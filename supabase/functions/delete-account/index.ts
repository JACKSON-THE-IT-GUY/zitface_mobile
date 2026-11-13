import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const authorization = request.headers.get("Authorization");
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  const projectUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!token || !projectUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse({ error: "Missing authorization or server configuration." }, 401);
  }

  let password: unknown;
  try {
    password = (await request.json())?.password;
  } catch {
    return jsonResponse({ error: "A password is required to confirm deletion." }, 400);
  }
  if (typeof password !== "string" || password.length === 0) {
    return jsonResponse({ error: "A password is required to confirm deletion." }, 400);
  }

  const userClient = createClient(projectUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser(token);
  if (userError || !userData.user) {
    return jsonResponse({ error: "A valid signed-in session is required." }, 401);
  }
  const userEmail = userData.user.email;
  if (!userEmail) {
    return jsonResponse({ error: "An email-based account is required." }, 403);
  }
  const { data: confirmation, error: confirmationError } =
    await userClient.auth.signInWithPassword({
      email: userEmail,
      password,
    });
  if (confirmationError || confirmation.user?.id !== userData.user.id) {
    return jsonResponse({ error: "Password confirmation failed." }, 403);
  }

  const admin = createClient(projectUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  async function collectOwnedFiles(bucket: string, ownerId: string): Promise<string[]> {
    const paths: string[] = [];

    async function visit(prefix: string): Promise<void> {
      let offset = 0;
      while (true) {
        const { data, error } = await admin.storage.from(bucket).list(prefix, {
          limit: 100,
          offset,
        });
        if (error) throw error;
        if (!data.length) return;

        for (const item of data) {
          const path = `${prefix}/${item.name}`;
          if (item.id === null) {
            await visit(path);
          } else {
            paths.push(path);
          }
        }
        if (data.length < 100) return;
        offset += data.length;
      }
    }

    await visit(ownerId);
    for (let index = 0; index < paths.length; index += 100) {
      const { error } = await admin.storage.from(bucket).remove(
        paths.slice(index, index + 100),
      );
      if (error) throw error;
    }
    return paths;
  }

  try {
    const ownerId = userData.user.id;
    for (const bucket of [
      "avatars",
      "post-media",
      "story-media",
      "story-audio",
      "market-media",
    ]) {
      await collectOwnedFiles(bucket, ownerId);
    }

    const { error } = await admin.auth.admin.deleteUser(ownerId);
    if (error) throw error;
    return jsonResponse({ deleted: true }, 200);
  } catch (error) {
    console.error("Account deletion failed", error);
    return jsonResponse({ error: "Account deletion could not be completed." }, 500);
  }
});