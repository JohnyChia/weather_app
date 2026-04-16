// @ts-nocheck
// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// @ts-nocheck
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { email } = await req.json();
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const searchEmail = email.trim().toLowerCase();

    // 1. 生成 OTP
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    console.log(`Step 1: Generated OTP ${otp} for ${searchEmail}`);

    // 2. 先更新数据库 (这是最重要的一步)
    const { error: dbError } = await supabase
      .from("users")
      .update({
        otp: otp,
        otp_create_time: new Date().toISOString()
      })
      .eq("email", searchEmail);

    if (dbError) throw new Error("Database update failed: " + dbError.message);
    console.log("Step 2: Database updated successfully");

    // 3. 发送邮件
    console.log("Step 3: Sending email via Brevo...");
    const brevoRes = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "accept": "application/json",
        "api-key": Deno.env.get("BREVO_API_KEY")!,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        sender: { name: "TARUMT App", email: "johnychia731@gmail.com" },
        to: [{ email: searchEmail }],
        subject: "Your Reset OTP",
        htmlContent: `<h2>OTP: ${otp}</h2>`,
      }),
    });

    if (!brevoRes.ok) {
       const errorText = await brevoRes.text();
       // 即使邮件发送失败，数据库其实已经更新了，所以我们抛出错误提示用户
       throw new Error("Email provider error: " + errorText);
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (err) {
    console.error("Critical Error:", err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
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
