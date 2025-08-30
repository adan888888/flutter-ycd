const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

// 手动处理CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Device-Type, X-Device-Id, X-Lang, X-Platform-Id, X-App-Terminal-Id, UserId');
  
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// 代理配置
app.use('/api', createProxyMiddleware({
  target: 'http://localhost:3000',
  changeOrigin: true,
  // 不需要路径重写，直接转发
  onProxyReq: (proxyReq, req, res) => {
    console.log('代理请求:', req.method, req.url);
    console.log('转发到:', proxyReq.path);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log('代理响应:', proxyRes.statusCode, req.url);
    // 添加CORS头部
    proxyRes.headers['Access-Control-Allow-Origin'] = '*';
    proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
    proxyRes.headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, X-Device-Type, X-Device-Id, X-Lang, X-Platform-Id, X-App-Terminal-Id, UserId';
  }
}));

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`代理服务器运行在 http://localhost:${PORT}`);
  console.log(`代理到后端服务器 http://localhost:3000`);
});
