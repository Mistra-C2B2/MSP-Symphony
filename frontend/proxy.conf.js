const TARGETS_CONFIG = {
  remote: {
    host: 'https://myserver:8443',
  },
  local: {
    host: 'http://127.0.0.1:8080',
  },
};

const targets = TARGETS_CONFIG[process.env.PROXY_TARGET ?? 'remote'];
const PROXY_CONFIG = {
  '/symphony-ws/service/*': {
    target: targets.host,
    secure: false,
    logLevel: 'debug',
    changeOrigin: true,
    onProxyReq: (proxyReq, req, res) => {
      console.log(`[PROXY REQ] ${req.method} ${req.url} → ${targets.host}${req.url}`);
    },
    onProxyRes: (proxyRes, req, res) => {
      console.log(`[PROXY RES] ${req.method} ${req.url} ← ${proxyRes.statusCode}`);
    },
    onError: (err, req, res) => {
      console.error(`[PROXY ERR] ${req.method} ${req.url}`, err);
    },
  },
  '/socket': {
    target: targets.host,
    pathRewrite: { '^/socket': '/symphony-ws' },
    secure: false,
    ws: true,
  },
};

console.log('>>> Loaded proxy.conf.js, targeting:', targets.host);
module.exports = PROXY_CONFIG;
