// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

serve(async (req) => {
  try {
    const { email, otp, newPassword } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // STEP 1: FIND USER IN PUBLIC TABLE
    const { data: users, error } = await supabase
      .from("users")
      .select("*")
      .eq("email", email.trim().toLowerCase());

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    if (!users || users.length === 0) {
      return new Response(JSON.stringify({ error: "user not found (public table)" }), { status: 400 });
    }

    const profile = users[0];

    // STEP 2: OTP CHECK
    if (profile.otp !== otp) {
      return new Response(JSON.stringify({ error: "invalid otp" }), { status: 400 });
    }

    // STEP 3: GET AUTH USER BY EMAIL (IMPORTANT FIX)
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();

    if (authError) {
      return new Response(JSON.stringify({ error: authError.message }), { status: 500 });
    }

    const authUser = authUsers.users.find(
      (u) => u.email === email.trim().toLowerCase()
    );

    if (!authUser) {
      return new Response(JSON.stringify({ error: "auth user not found" }), { status: 400 });
    }

    // STEP 4: UPDATE PASSWORD (REAL FIX)
    const { error: updateError } = await supabase.auth.admin.updateUserById(
      authUser.id,
      { password: newPassword }
    );

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), { status: 500 });
    }

    // STEP 5: CLEAR OTP
    await supabase
      .from("users")
      .update({ otp: null, otp_create_time: null })
      .eq("email", email);

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
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
