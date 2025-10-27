// src/routes/chatRoutes.js
const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

// GET /api/chat/mensajes - Obtener mensajes recientes
router.get('/mensajes', chatController.getMensajes);

// POST /api/chat/enviar - Enviar un mensaje
router.post('/enviar', chatController.enviarMensaje);

// GET /api/chat/parada/:paradaId - Obtener mensajes de una parada
router.get('/parada/:paradaId', chatController.getMensajesParada);

// GET /api/chat/ruta/:rutaId - Obtener mensajes de una ruta
router.get('/ruta/:rutaId', chatController.getMensajesRuta);

// DELETE /api/chat/limpiar - Limpiar mensajes antiguos (admin/cron)
router.delete('/limpiar', chatController.limpiarMensajesAntiguos);

module.exports = router;