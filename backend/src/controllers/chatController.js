const db = require('../config/database');

// Obtener mensajes recientes (últimos 50)
exports.getMensajes = async (req, res) => {
  try {
    const { tipo = 'general', limite = 50 } = req.query;
    
    const result = await db.query(
      `SELECT 
        id,
        username,
        mensaje,
        parada_id,
        ruta_id,
        tipo,
        fecha_envio
      FROM mensajes_chat
      WHERE tipo = $1
      ORDER BY fecha_envio DESC
      LIMIT $2`,
      [tipo, parseInt(limite)]
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows.reverse() // Invertir para mostrar más antiguos primero
    });
  } catch (error) {
    console.error('Error al obtener mensajes:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener mensajes',
      error: error.message
    });
  }
};

// Enviar mensaje
exports.enviarMensaje = async (req, res) => {
  try {
    const { username, mensaje, parada_id, ruta_id, tipo = 'general' } = req.body;

    // Validaciones
    if (!username || !mensaje) {
      return res.status(400).json({
        success: false,
        message: 'Username y mensaje son requeridos'
      });
    }

    if (mensaje.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'El mensaje no puede estar vacío'
      });
    }

    if (mensaje.length > 500) {
      return res.status(400).json({
        success: false,
        message: 'El mensaje no puede exceder 500 caracteres'
      });
    }

    const result = await db.query(
      `INSERT INTO mensajes_chat 
        (username, mensaje, parada_id, ruta_id, tipo)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *`,
      [username, mensaje.trim(), parada_id || null, ruta_id || null, tipo]
    );

    const nuevoMensaje = result.rows[0];

    // Emitir por WebSocket a todos los clientes conectados
    if (req.io) {
      req.io.emit('nuevo-mensaje', nuevoMensaje);
      
      // Si es de una parada específica, emitir a ese canal
      if (parada_id) {
        req.io.to(`parada-${parada_id}`).emit('nuevo-mensaje-parada', nuevoMensaje);
      }
      
      // Si es de una ruta específica, emitir a ese canal
      if (ruta_id) {
        req.io.to(`ruta-${ruta_id}`).emit('nuevo-mensaje-ruta', nuevoMensaje);
      }
    }

    res.status(201).json({
      success: true,
      message: 'Mensaje enviado correctamente',
      data: nuevoMensaje
    });
  } catch (error) {
    console.error('Error al enviar mensaje:', error);
    res.status(500).json({
      success: false,
      message: 'Error al enviar mensaje',
      error: error.message
    });
  }
};

// Obtener mensajes de una parada específica
exports.getMensajesParada = async (req, res) => {
  try {
    const { paradaId } = req.params;
    const { limite = 30 } = req.query;

    const result = await db.query(
      `SELECT 
        id,
        username,
        mensaje,
        parada_id,
        fecha_envio
      FROM mensajes_chat
      WHERE parada_id = $1
      ORDER BY fecha_envio DESC
      LIMIT $2`,
      [parseInt(paradaId), parseInt(limite)]
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows.reverse()
    });
  } catch (error) {
    console.error('Error al obtener mensajes de parada:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener mensajes de parada',
      error: error.message
    });
  }
};

// Obtener mensajes de una ruta específica
exports.getMensajesRuta = async (req, res) => {
  try {
    const { rutaId } = req.params;
    const { limite = 30 } = req.query;

    const result = await db.query(
      `SELECT 
        id,
        username,
        mensaje,
        ruta_id,
        fecha_envio
      FROM mensajes_chat
      WHERE ruta_id = $1
      ORDER BY fecha_envio DESC
      LIMIT $2`,
      [parseInt(rutaId), parseInt(limite)]
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows.reverse()
    });
  } catch (error) {
    console.error('Error al obtener mensajes de ruta:', error);
    res.status(500).json({
      success: false,
      message: 'Error al obtener mensajes de ruta',
      error: error.message
    });
  }
};

// Eliminar mensajes antiguos (mantenimiento automático)
exports.limpiarMensajesAntiguos = async (req, res) => {
  try {
    // Eliminar mensajes de más de 7 días
    const result = await db.query(
      `DELETE FROM mensajes_chat
       WHERE fecha_envio < NOW() - INTERVAL '7 days'
       RETURNING id`
    );

    res.json({
      success: true,
      message: `${result.rowCount} mensajes antiguos eliminados`
    });
  } catch (error) {
    console.error('Error al limpiar mensajes:', error);
    res.status(500).json({
      success: false,
      message: 'Error al limpiar mensajes',
      error: error.message
    });
  }
};