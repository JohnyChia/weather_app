// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import bcrypt from "https://esm.sh/bcryptjs";

serve(async (req) => {
  try {
    const { email, otp, newPassword } = await req.json();

    if (!email || !otp || !newPassword) {
      return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // 1. get user
    const { data: user, error } = await supabase
      .from("users")
      .select("otp, otp_create_time")
      .eq("email", email.trim().toLowerCase())
      .single();

    if (error || !user) {
      return new Response(JSON.stringify({ error: "User not found" }), { status: 400 });
    }

    // 2. check OTP
    if (user.otp !== otp) {
      return new Response(JSON.stringify({ error: "Invalid OTP" }), { status: 400 });
    }

    // 3. check expiry (5 min)
    const created = new Date(user.otp_create_time).getTime();
    const now = Date.now();

    if ((now - created) > 5 * 60 * 1000) {
      return new Response(JSON.stringify({ error: "OTP expired" }), { status: 400 });
    }

    // 4. hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // 5. update password + clear OTP
    const { error: updateError } = await supabase
      .from("users")
      .update({
        password: hashedPassword,
        otp: null,
        otp_create_time: null,
      })
      .eq("email", email.trim().toLowerCase());

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/reset-password' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/