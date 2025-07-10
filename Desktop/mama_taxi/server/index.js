require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');

// Инициализация приложения Express
const app = express();
const PORT = process.env.PORT || 3000;

// Инициализация клиента Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://your-supabase-url.supabase.co';
const supabaseKey = process.env.SUPABASE_KEY || 'your-supabase-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Настройка хранилища для загрузки файлов
const storage = multer.diskStorage({
  destination: function(req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function(req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });

// Middleware для проверки JWT токена
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Требуется авторизация' });
  }
  
  jwt.verify(token, process.env.JWT_SECRET || 'your-jwt-secret', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Недействительный токен' });
    }
    
    req.user = user;
    next();
  });
};

// Middleware для проверки роли администратора
const isAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Доступ запрещен. Требуются права администратора.' });
  }
  
  next();
};

// Маршрут для аутентификации
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password, authCode } = req.body;
    
    // Проверка учетных данных (в реальном приложении данные должны быть в базе данных)
    if (username === 'admin' && password === 'admin123' && authCode === 'MAMA2023') {
      // Создание JWT токена
      const token = jwt.sign(
        { id: 1, username: 'admin', role: 'admin' },
        process.env.JWT_SECRET || 'your-jwt-secret',
        { expiresIn: '24h' }
      );
      
      return res.json({ token });
    }
    
    return res.status(401).json({ error: 'Неверные учетные данные' });
  } catch (error) {
    console.error('Ошибка входа:', error);
    res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
});

// Маршруты для работы с водителями
app.get('/api/drivers', authenticateToken, isAdmin, async (req, res) => {
  try {
    // Получение списка водителей из Supabase
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'driver');
    
    if (error) throw error;
    
    res.json(data);
  } catch (error) {
    console.error('Ошибка получения водителей:', error);
    res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
});

// Маршрут для получения водителей, ожидающих верификации
app.get('/api/drivers/pending-verification', authenticateToken, isAdmin, async (req, res) => {
  try {
    // Получение списка водителей, ожидающих верификации
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'driver')
      .eq('verification_status', 'pending');
    
    if (error) throw error;
    
    res.json(data);
  } catch (error) {
    console.error('Ошибка получения водителей:', error);
    res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
});

// Маршрут для получения документов водителя
app.get('/api/drivers/:id/documents', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Получение документов водителя
    const { data, error } = await supabase
      .from('driver_documents')
      .select('*')
      .eq('driver_id', id);
    
    if (error) throw error;
    
    res.json(data);
  } catch (error) {
    console.error('Ошибка получения документов:', error);
    res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
});

// Маршрут для подтверждения документов водителя
app.post('/api/drivers/:id/verify', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, comment } = req.body;
    
    // Обновление статуса верификации водителя
    const { data, error } = await supabase
      .from('profiles')
      .update({ 
        verification_status: status,
        verification_comment: comment,
        verified_at: status === 'approved' ? new Date() : null,
        verified_by: req.user.id
      })
      .eq('id', id)
      .eq('role', 'driver');
    
    if (error) throw error;
    
    // Запись действия в журнал
    await supabase
      .from('admin_actions')
      .insert({
        admin_id: req.user.id,
        action_type: `driver_verification_${status}`,
        target_id: id,
        details: { comment }
      });
    
    res.json({ success: true, message: `Статус верификации водителя обновлен на ${status}` });
  } catch (error) {
    console.error('Ошибка верификации водителя:', error);
    res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
});

// Маршруты для работы с поездками
app.get('/api/rides', authenticateToken, isAdmin, async (req, res) => {
  try {
    const { status } = req.query;
    
    // Базовый запрос
    let query = supabase
      .from('rides')
      .select('*, driver:profiles(*), client:profiles(*)');
    
    // Добавление фильтра по статусу, если он указан
    if (status) {
      query = query.eq('status', status);
    }
    
    // Выполнение запроса
    const { data, error } = await query;
    
    if (error) throw error;
    
    res.json(data);
  } catch (error) {
    console.error('Ошибка получения поездок:', error);
    res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
});

// Маршрут для получения статистики
app.get('/api/stats', authenticateToken, isAdmin, async (req, res) => {
  try {
    // Получение количества активных поездок
    const { data: activeRides, error: activeRidesError } = await supabase
      .from('rides')
      .select('count', { count: 'exact' })
      .eq('status', 'active');
    
    if (activeRidesError) throw activeRidesError;
    
    // Получение количества водителей, ожидающих верификации
    const { data: pendingDrivers, error: pendingDriversError } = await supabase
      .from('profiles')
      .select('count', { count: 'exact' })
      .eq('role', 'driver')
      .eq('verification_status', 'pending');
    
    if (pendingDriversError) throw pendingDriversError;
    
    // Получение количества завершенных поездок за сегодня
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const { data: completedToday, error: completedTodayError } = await supabase
      .from('rides')
      .select('count', { count: 'exact' })
      .eq('status', 'completed')
      .gte('completed_at', today.toISOString());
    
    if (completedTodayError) throw completedTodayError;
    
    // Получение общей выручки за сегодня
    const { data: revenueToday, error: revenueTodayError } = await supabase
      .from('rides')
      .select('sum(amount)')
      .eq('status', 'completed')
      .gte('completed_at', today.toISOString());
    
    if (revenueTodayError) throw revenueTodayError;
    
    res.json({
      activeRides: activeRides[0].count,
      pendingDrivers: pendingDrivers[0].count,
      completedToday: completedToday[0].count,
      revenueToday: revenueToday[0].sum || 0
    });
  } catch (error) {
    console.error('Ошибка получения статистики:', error);
    res.status(500).json({ error: 'Внутренняя ошибка сервера' });
  }
});

// Запуск сервера
app.listen(PORT, () => {
  console.log(`Сервер запущен на порту ${PORT}`);
}); 