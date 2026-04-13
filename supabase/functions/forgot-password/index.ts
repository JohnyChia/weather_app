// @ts-nocheck
// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

serve(async (req) => {
  try {
    const { email } = await req.json();

    if (!email) {
      return new Response(JSON.stringify({ error: "Email required" }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // 1. check user exists
    const { data: user, error } = await supabase
      .from("users")
      .select("email, otp_create_time")
      .eq("email", email.trim().toLowerCase())
      .single();

    if (error || !user) {
      return new Response(JSON.stringify({ error: "User not found" }), { status: 400 });
    }

    // 2. rate limit (60s)
    if (user.otp_create_time) {
      const diff = Date.now() - new Date(user.otp_create_time).getTime();
      if (diff < 60000) {
        return new Response(JSON.stringify({ error: "Wait 60s before requesting again" }), { status: 429 });
      }
    }

    // 3. generate OTP
    const otp = Math.floor(1000 + Math.random() * 9000).toString();

    // 4. save OTP
    const { error: updateError } = await supabase
      .from("users")
      .update({
        otp,
        otp_create_time: new Date().toISOString(),
      })
      .eq("email", email.trim().toLowerCase());

    if (updateError) {
      return new Response(JSON.stringify({ error: "DB update failed" }), { status: 500 });
    }

    // 5. send email
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("RESEND_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "onboarding@resend.dev",
        to: email,
        subject: "Reset Password OTP",
        html: `<h2>Your OTP: ${otp}</h2>`,
      }),
    });

    if (!res.ok) {
      return new Response(JSON.stringify({ error: "Email failed" }), { status: 500 });
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/forgot-password' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
