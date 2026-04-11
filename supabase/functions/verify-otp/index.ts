// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

serve(async (req) => {
  const { email, otp } = await req.json();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SERVICE_ROLE_KEY")!
  );

  // 1. get user
  const { data: user, error } = await supabase
    .from("users")
    .select("otp, otp_create_time")
    .eq("email", email)

  if (error || !user) {
    return new Response(JSON.stringify({ success: false, message: "User not found" }), {
      status: 400,
    });
  }

  // 2. check OTP match
  if (user.otp !== otp) {
    return new Response(JSON.stringify({ success: false, message: "Invalid OTP" }), {
      status: 400,
    });
  }

  // 3. check expiry (5 minutes)
  const created = new Date(user.otp_create_time).getTime();
  const now = Date.now();

  const diffMin = (now - created) / 1000 / 60;

  if (diffMin > 5) {
    return new Response(JSON.stringify({ success: false, message: "OTP expired" }), {
      status: 400,
    });
  }

  // 4. clear OTP after success
  await supabase
    .from("users")
    .update({
      otp: null,
      otp_create_time: null,
    })
    .eq("email", email);

  return new Response(JSON.stringify({ success: true, message: "OTP verified" }), {
    headers: { "Content-Type": "application/json" },
  });
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/verify-otp' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
