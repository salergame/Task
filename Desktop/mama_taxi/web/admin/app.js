// Конфигурация Supabase
const SUPABASE_URL = 'https://pshoujaaainxxkjzjukz.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzaG91amFhYWlueHhranpqdWt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg3MDgzODYsImV4cCI6MjA2NDI4NDM4Nn0.M6AoM5lehMQ1LXvGmMzqdipE9FynMSNY7UM6ZWQrsjw';

// Инициализация клиента Supabase
let supabase = null;

// Проверка аутентификации
function checkAuth() {
  const token = sessionStorage.getItem('auth_token');
  
  if (!token) {
    window.location.href = 'login.html';
    return false;
  }
  
  return true;
}

// Выход из системы
function logout() {
  supabase.auth.signOut().then(() => {
    sessionStorage.removeItem('auth_token');
    sessionStorage.removeItem('authenticated');
    window.location.href = 'login.html';
  });
}

// Инициализация Supabase
function initSupabase() {
  if (!supabase) {
    supabase = supabaseClient.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }
  return supabase;
}

// Обработчики событий
document.addEventListener('DOMContentLoaded', function() {
  // Инициализация Supabase
  initSupabase();
  
  // Проверка аутентификации на всех страницах, кроме страницы входа
  if (!window.location.href.includes('login.html')) {
    if (!checkAuth()) return;
    
    // Обработчик для кнопки выхода
    const logoutBtn = document.querySelector('.nav-item.logout');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', logout);
    }
    
    // Загрузка данных для текущей страницы
    if (window.location.href.includes('index.html') || window.location.pathname.endsWith('/admin/')) {
      loadDashboardData();
    } else if (window.location.href.includes('verification.html')) {
      initVerificationPage();
    }
  } else {
    // Обработчик для формы входа
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
      loginForm.addEventListener('submit', async function(event) {
        event.preventDefault();
        
        const email = document.getElementById('username').value;
        const password = document.getElementById('password').value;
        const authCode = document.getElementById('auth-code').value;
        const errorMessage = document.getElementById('error-message');
        
        try {
          // Проверяем код авторизации
          if (authCode !== 'MAMA2023') {
            throw new Error('Неверный код авторизации');
          }
          
          // Отправка запроса на аутентификацию
          const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
          });
          
          if (error) {
            throw new Error(error.message || 'Неверные учетные данные');
          }
          
          // Проверяем роль администратора
          const { data: profileData, error: profileError } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', data.user.id)
            .single();
          
          if (profileError) {
            throw new Error(profileError.message || 'Ошибка получения профиля');
          }
          
          if (profileData.role !== 'admin') {
            throw new Error('У вас недостаточно прав для доступа к админ-панели');
          }
          
          // Сохранение токена в sessionStorage
          sessionStorage.setItem('auth_token', data.session.access_token);
          sessionStorage.setItem('authenticated', 'true');
          sessionStorage.setItem('user_id', data.user.id);
          
          // Перенаправление на главную страницу админ-панели
          window.location.href = 'index.html';
        } catch (error) {
          errorMessage.textContent = error.message;
          errorMessage.style.display = 'block';
        }
      });
    }
  }
});

// Загрузка данных для дашборда
async function loadDashboardData() {
  try {
    // Получаем статистику активных поездок
    const { data: activeRides, error: activeRidesError } = await supabase
      .from('rides')
      .select('id')
      .eq('status', 'active');
      
    if (activeRidesError) throw activeRidesError;
    
    // Получаем количество водителей, ожидающих верификации
    const { data: pendingDrivers, error: pendingDriversError } = await supabase
      .from('profiles')
      .select('id')
      .eq('role', 'driver')
      .eq('verification_status', 'pending');
      
    if (pendingDriversError) throw pendingDriversError;
    
    // Получаем статистику завершенных поездок за сегодня
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString();
    
    const { data: completedToday, error: completedTodayError } = await supabase
      .from('rides')
      .select('amount')
      .eq('status', 'completed')
      .gte('completed_at', startOfDay);
      
    if (completedTodayError) throw completedTodayError;
    
    // Рассчитываем выручку за сегодня
    let revenueTodaySum = 0;
    completedToday.forEach(ride => {
      revenueTodaySum += (ride.amount || 0);
    });
    
    // Обновление статистики на странице
    document.querySelector('.stats-card:nth-child(1) .stats-value').textContent = activeRides.length;
    
    // Обновление счетчика водителей, ожидающих верификации
    const pendingDriversElement = document.querySelector('.stats-card:nth-child(2) .stats-value');
    if (pendingDriversElement) {
      pendingDriversElement.textContent = pendingDrivers.length;
    }
    
    // Обновление счетчика поездок за сегодня
    const completedTodayElement = document.querySelector('.stats-card:nth-child(3) .stats-value');
    if (completedTodayElement) {
      completedTodayElement.textContent = completedToday.length;
    }
    
    // Обновление выручки за сегодня
    const revenueTodayElement = document.querySelector('.stats-card:nth-child(4) .stats-value');
    if (revenueTodayElement) {
      revenueTodayElement.textContent = `${revenueTodaySum} ₽`;
    }
    
    // Загрузка активных поездок для карты
    const { data: rides, error: ridesError } = await supabase
      .from('rides')
      .select('*, driver:driver_id(*), client:client_id(*)')
      .eq('status', 'active');
      
    if (ridesError) throw ridesError;
    
    updateMap(rides);
    updateRecentActionsTable(rides);
    
    // Загрузка последних действий администраторов
    const { data: adminActions, error: adminActionsError } = await supabase
      .from('admin_actions')
      .select('*, admin:admin_id(*)')
      .order('created_at', { ascending: false })
      .limit(5);
      
    if (adminActionsError) throw adminActionsError;
    
    // Можно добавить вывод последних действий администраторов в отдельную таблицу
  } catch (error) {
    console.error('Ошибка загрузки данных дашборда:', error);
    alert('Не удалось загрузить данные. Пожалуйста, попробуйте позже.');
  }
}

// Обновление карты активных поездок
function updateMap(rides) {
  // Проверяем, инициализирована ли карта
  if (typeof ymaps !== 'undefined' && ymaps.Map) {
    ymaps.ready(function() {
      const map = new ymaps.Map('map', {
        center: [55.751574, 37.573856], // Москва
        zoom: 11,
        controls: ['zoomControl']
      });
      
      // Добавление автомобилей на карту
      rides.forEach(ride => {
        if (ride.driver && ride.driver.location) {
          const placemark = new ymaps.Placemark(ride.driver.location, {
            hintContent: `Водитель: ${ride.driver.full_name || 'Неизвестно'}`,
            balloonContent: `
              <b>Водитель:</b> ${ride.driver.full_name || 'Неизвестно'}<br>
              <b>Клиент:</b> ${ride.client?.full_name || 'Неизвестно'}<br>
              <b>Сумма:</b> ₽${ride.amount || 0}
            `
          }, {
            iconLayout: 'default#image',
            iconImageHref: 'assets/car-icon.svg',
            iconImageSize: [24, 24],
            iconImageOffset: [-12, -12]
          });
          
          map.geoObjects.add(placemark);
        }
      });
    });
  }
}

// Обновление таблицы поездок
function updateRecentActionsTable(rides) {
  const tableBody = document.querySelector('.data-table tbody');
  if (!tableBody) return;
  
  // Очистка таблицы
  tableBody.innerHTML = '';
  
  // Заполнение таблицы данными
  rides.forEach(ride => {
    const row = document.createElement('tr');
    
    // Форматирование статуса
    let statusClass = '';
    switch (ride.status) {
      case 'active':
        statusClass = 'active';
        break;
      case 'completed':
        statusClass = 'completed';
        break;
      case 'pending':
        statusClass = 'pending';
        break;
    }
    
    row.innerHTML = `
      <td>#${ride.id}</td>
      <td>
        <div class="user-info">
          <img src="${ride.driver?.profile_image_url || 'assets/driver-avatar.jpg'}" alt="Водитель" class="user-avatar">
          <span>${ride.driver?.full_name || 'Неизвестно'}</span>
        </div>
      </td>
      <td>${ride.client?.full_name || 'Неизвестно'}</td>
      <td><span class="status-badge ${statusClass}">${formatStatus(ride.status)}</span></td>
      <td>₽${ride.amount || 0}</td>
      <td>
        <button class="action-btn" data-id="${ride.id}">
          <svg width="18" height="16" viewBox="0 0 18 16" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M9 3.33333C9.55228 3.33333 10 2.88562 10 2.33333C10 1.78105 9.55228 1.33333 9 1.33333C8.44772 1.33333 8 1.78105 8 2.33333C8 2.88562 8.44772 3.33333 9 3.33333Z" fill="black"/>
            <path d="M9 8.66667C9.55228 8.66667 10 8.21895 10 7.66667C10 7.11438 9.55228 6.66667 9 6.66667C8.44772 6.66667 8 7.11438 8 7.66667C8 8.21895 8.44772 8.66667 9 8.66667Z" fill="black"/>
            <path d="M9 14C9.55228 14 10 13.5523 10 13C10 12.4477 9.55228 12 9 12C8.44772 12 8 12.4477 8 13C8 13.5523 8.44772 14 9 14Z" fill="black"/>
          </svg>
        </button>
      </td>
    `;
    
    tableBody.appendChild(row);
  });
  
  // Добавление обработчиков для кнопок действий
  document.querySelectorAll('.action-btn').forEach(btn => {
    btn.addEventListener('click', function() {
      const rideId = this.getAttribute('data-id');
      alert(`Действия для поездки #${rideId}`);
    });
  });
}

// Функции для страницы верификации водителей
async function initVerificationPage() {
  try {
    // Загрузка водителей, ожидающих верификации
    const { data: drivers, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'driver')
      .eq('verification_status', 'pending');
      
    if (error) throw error;
    
    // Обновление таблицы водителей
    updateDriversTable(drivers);
    
    // Обработчики для фильтров
    document.getElementById('status-filter').addEventListener('change', filterDrivers);
    document.getElementById('date-filter').addEventListener('change', filterDrivers);
    document.getElementById('search').addEventListener('input', filterDrivers);
    
    // Обработчик для пагинации
    document.querySelectorAll('.pagination-btn').forEach(button => {
      button.addEventListener('click', function() {
        if (this.disabled) return;
        
        document.querySelectorAll('.pagination-btn').forEach(btn => {
          btn.classList.remove('active');
        });
        
        this.classList.add('active');
        
        // Загрузка данных для выбранной страницы
        const page = this.textContent;
        loadDriversPage(page);
      });
    });
  } catch (error) {
    console.error('Ошибка инициализации страницы верификации:', error);
    alert('Не удалось загрузить данные. Пожалуйста, попробуйте позже.');
  }
}

// Обновление таблицы водителей
function updateDriversTable(drivers) {
  const tableBody = document.querySelector('.verification-table-container tbody');
  if (!tableBody) return;
  
  // Очистка таблицы
  tableBody.innerHTML = '';
  
  // Заполнение таблицы данными
  drivers.forEach(driver => {
    const row = document.createElement('tr');
    
    // Форматирование статуса
    let statusClass = '';
    switch (driver.verification_status) {
      case 'pending':
        statusClass = 'pending';
        break;
      case 'approved':
        statusClass = 'approved';
        break;
      case 'rejected':
        statusClass = 'rejected';
        break;
    }
    
    // Форматирование даты
    const submittedDate = new Date(driver.created_at);
    const formattedDate = `${submittedDate.toLocaleDateString()}, ${submittedDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
    
    row.innerHTML = `
      <td>#${driver.id}</td>
      <td>
        <div class="user-info">
          <img src="${driver.profile_image_url || 'assets/driver-avatar.jpg'}" alt="Водитель" class="user-avatar">
          <span>${driver.full_name || driver.email}</span>
        </div>
      </td>
      <td>
        <div class="documents">
          <span class="document-badge">Документы</span>
        </div>
      </td>
      <td>${formattedDate}</td>
      <td><span class="status-badge ${statusClass}">${formatVerificationStatus(driver.verification_status)}</span></td>
      <td>
        <div class="action-buttons">
          <button class="btn btn-primary btn-sm view-btn" data-id="${driver.id}">Просмотр</button>
        </div>
      </td>
    `;
    
    tableBody.appendChild(row);
  });
  
  // Добавление обработчиков для кнопок просмотра
  setupViewButtons();
}

// Настройка обработчиков для кнопок просмотра
function setupViewButtons() {
  const viewButtons = document.querySelectorAll('.view-btn');
  const modal = document.getElementById('document-modal');
  const closeBtn = document.querySelector('.close-btn');
  const approveBtn = document.getElementById('approve-btn');
  const rejectBtn = document.getElementById('reject-btn');
  
  if (!viewButtons || !modal || !closeBtn || !approveBtn || !rejectBtn) return;
  
  // Открытие модального окна
  viewButtons.forEach(button => {
    button.addEventListener('click', async function() {
      const driverId = this.getAttribute('data-id');
      
      try {
        // Загрузка данных водителя
        const { data: driver, error: driverError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', driverId)
          .single();
          
        if (driverError) throw driverError;
        
        // Загрузка документов водителя
        const { data: documents, error: documentsError } = await supabase
          .from('driver_documents')
          .select('*')
          .eq('driver_id', driverId);
          
        if (documentsError) throw documentsError;
        
        // Обновление модального окна данными водителя
        document.getElementById('driver-name').textContent = driver.full_name || driver.email;
        document.getElementById('driver-id').textContent = `#${driver.id}`;
        document.getElementById('driver-phone').textContent = driver.phone || 'Не указан';
        document.getElementById('driver-email').textContent = driver.email;
        
        // Отображение документов
        updateDocumentImages(documents);
        
        // Отображение модального окна
        modal.style.display = 'flex';
      } catch (error) {
        console.error('Ошибка загрузки данных водителя:', error);
        alert('Не удалось загрузить данные водителя. Пожалуйста, попробуйте позже.');
      }
    });
  });
  
  // Закрытие модального окна
  closeBtn.addEventListener('click', function() {
    modal.style.display = 'none';
  });
  
  // Закрытие модального окна при клике вне его
  window.addEventListener('click', function(event) {
    if (event.target === modal) {
      modal.style.display = 'none';
    }
  });
  
  // Подтверждение документов
  approveBtn.addEventListener('click', async function() {
    const driverId = document.getElementById('driver-id').textContent.substring(1);
    const comment = document.getElementById('admin-comment').value;
    
    try {
      // Обновление статуса верификации водителя
      const { error: updateError } = await supabase
        .from('profiles')
        .update({
          verification_status: 'approved',
          verification_comment: comment,
          verified_at: new Date().toISOString(),
          verified_by: sessionStorage.getItem('user_id'),
        })
        .eq('id', driverId)
        .eq('role', 'driver');
      
      if (updateError) throw updateError;
      
      // Запись действия в журнал
      const { error: logError } = await supabase
        .from('admin_actions')
        .insert({
          admin_id: sessionStorage.getItem('user_id'),
          action_type: 'driver_verification_approved',
          target_id: driverId,
          details: { comment },
          created_at: new Date().toISOString(),
        });
      
      if (logError) throw logError;
      
      alert(`Документы водителя ${driverId} подтверждены.`);
      modal.style.display = 'none';
      
      // Обновление таблицы водителей
      initVerificationPage();
    } catch (error) {
      console.error('Ошибка подтверждения документов:', error);
      alert('Не удалось подтвердить документы. Пожалуйста, попробуйте позже.');
    }
  });
  
  // Отклонение документов
  rejectBtn.addEventListener('click', async function() {
    const driverId = document.getElementById('driver-id').textContent.substring(1);
    const comment = document.getElementById('admin-comment').value;
    
    if (!comment) {
      alert('Пожалуйста, укажите причину отклонения в комментарии.');
      return;
    }
    
    try {
      // Обновление статуса верификации водителя
      const { error: updateError } = await supabase
        .from('profiles')
        .update({
          verification_status: 'rejected',
          verification_comment: comment,
          verified_at: new Date().toISOString(),
          verified_by: sessionStorage.getItem('user_id'),
        })
        .eq('id', driverId)
        .eq('role', 'driver');
      
      if (updateError) throw updateError;
      
      // Запись действия в журнал
      const { error: logError } = await supabase
        .from('admin_actions')
        .insert({
          admin_id: sessionStorage.getItem('user_id'),
          action_type: 'driver_verification_rejected',
          target_id: driverId,
          details: { comment },
          created_at: new Date().toISOString(),
        });
      
      if (logError) throw logError;
      
      alert(`Документы водителя ${driverId} отклонены.`);
      modal.style.display = 'none';
      
      // Обновление таблицы водителей
      initVerificationPage();
    } catch (error) {
      console.error('Ошибка отклонения документов:', error);
      alert('Не удалось отклонить документы. Пожалуйста, попробуйте позже.');
    }
  });
}

// Обновление изображений документов в модальном окне
function updateDocumentImages(documents) {
  const imageContainers = document.querySelectorAll('.document-image img');
  
  // Сброс всех изображений к заглушке
  imageContainers.forEach(img => {
    img.src = 'assets/document-placeholder.jpg';
  });
  
  // Обновление изображений документов
  documents.forEach(doc => {
    // Находим соответствующий контейнер для изображения
    let container = null;
    switch (doc.document_type) {
      case 'passport':
        container = document.querySelector('.document-section:nth-child(1) .document-image:nth-child(1) img');
        break;
      case 'driver_license':
        container = document.querySelector('.document-section:nth-child(2) .document-image:nth-child(1) img');
        break;
      case 'vehicle_registration':
        container = document.querySelector('.document-section:nth-child(3) .document-image:nth-child(1) img');
        break;
    }
    
    if (container && doc.file_url) {
      container.src = doc.file_url;
    }
  });
}

// Фильтрация водителей
function filterDrivers() {
  const status = document.getElementById('status-filter').value;
  const date = document.getElementById('date-filter').value;
  const search = document.getElementById('search').value.toLowerCase();
  
  const rows = document.querySelectorAll('.verification-table-container tbody tr');
  
  rows.forEach(row => {
    let showRow = true;
    
    // Фильтр по статусу
    if (status !== 'all') {
      const rowStatus = row.querySelector('.status-badge').className;
      if (!rowStatus.includes(status)) {
        showRow = false;
      }
    }
    
    // Фильтр по дате (упрощенный)
    if (date !== 'all' && showRow) {
      // Здесь должна быть логика фильтрации по дате
      // Для демонстрации просто оставляем как есть
    }
    
    // Фильтр по поиску
    if (search && showRow) {
      const driverName = row.querySelector('.user-info span').textContent.toLowerCase();
      const driverId = row.querySelector('td:first-child').textContent.toLowerCase();
      
      if (!driverName.includes(search) && !driverId.includes(search)) {
        showRow = false;
      }
    }
    
    // Отображение или скрытие строки
    row.style.display = showRow ? '' : 'none';
  });
}

// Загрузка страницы водителей с пагинацией
async function loadDriversPage(page) {
  try {
    const pageSize = 10;
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    
    const { data: drivers, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('role', 'driver')
      .eq('verification_status', 'pending')
      .range(from, to);
      
    if (error) throw error;
    
    updateDriversTable(drivers);
  } catch (error) {
    console.error('Ошибка загрузки страницы водителей:', error);
    alert('Не удалось загрузить данные. Пожалуйста, попробуйте позже.');
  }
}

// Вспомогательные функции
function formatStatus(status) {
  switch (status) {
    case 'active':
      return 'Активен';
    case 'completed':
      return 'Завершен';
    case 'pending':
      return 'Ожидает';
    default:
      return status;
  }
}

function formatVerificationStatus(status) {
  switch (status) {
    case 'pending':
      return 'Ожидает проверки';
    case 'approved':
      return 'Подтвержден';
    case 'rejected':
      return 'Отклонен';
    default:
      return status;
  }
} 