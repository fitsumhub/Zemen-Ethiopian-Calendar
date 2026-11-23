import fs from 'fs';

const workerCode = fs.readFileSync('src/index.js', 'utf8');
const esc = JSON.stringify(workerCode);
const out = `async () => {
  const workerCode = ${esc};
  const metadata = {
    main_module: "index.js",
    bindings: [
      { type: "plain_text", name: "SPORTSDB_API_KEY", text: "123" },
      { type: "plain_text", name: "ALLOWED_ORIGINS", text: "*" }
    ],
    compatibility_date: "2024-11-01"
  };
  const form = new FormData();
  form.append("metadata", new Blob([JSON.stringify(metadata)], { type: "application/json" }));
  form.append("index.js", new Blob([workerCode], { type: "application/javascript+module" }), "index.js");
  const upload = await cloudflare.request({
    method: "PUT",
    path: \`/accounts/\${accountId}/workers/scripts/zemen-football-proxy\`,
    body: form,
  });
  let subdomain;
  try {
    subdomain = await cloudflare.request({
      method: "POST",
      path: \`/accounts/\${accountId}/workers/scripts/zemen-football-proxy/subdomain\`,
      body: { enabled: true },
    });
  } catch (e) {
    subdomain = { error: String(e) };
  }
  let accountSub;
  try {
    accountSub = await cloudflare.request({
      method: "GET",
      path: \`/accounts/\${accountId}/workers/subdomain\`,
    });
  } catch (e) {
    accountSub = { error: String(e) };
  }
  return { uploadSuccess: upload.success, id: upload.result?.id, subdomain, accountSub };
}`;

fs.writeFileSync('.mcp-deploy.js', out);
console.log('wrote .mcp-deploy.js bytes', Buffer.byteLength(out));
