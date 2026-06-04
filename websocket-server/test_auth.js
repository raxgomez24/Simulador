const WebSocket = require('ws');

const ws = new WebSocket('ws://localhost:8080');

ws.on('open', () => {
  console.log('Conectado al servidor WebSocket');
  
  const authMessage = {
    type: 'auth',
    action: 'login',
    username: 'juan',
    password: 'juan123'
  };
  
  console.log('Enviando mensaje:', JSON.stringify(authMessage));
  ws.send(JSON.stringify(authMessage));
});

ws.on('message', (data) => {
  const message = JSON.parse(data.toString());
  console.log('Mensaje recibido:', JSON.stringify(message, null, 2));
  ws.close();
});

ws.on('error', (error) => {
  console.error('Error de WebSocket:', error);
  ws.close();
});

ws.on('close', () => {
  console.log('Conexión cerrada');
});

setTimeout(() => {
  ws.close();
}, 5000);
