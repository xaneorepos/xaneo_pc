(async function testWebRateLimit() {
  const targetEmail = 'huskarnat@gmail.com';
  // Веб-эндпоинт отправки кодов регистрации
  const apiEndpoint = `/check-email/?email=${encodeURIComponent(targetEmail)}&username=security_test`;

  console.log('%c🚀 Запуск теста веб-уязвимости спама кодов...', 'color: #3b82f6; font-size: 14px; font-weight: bold;');

  const sendRequest = async () => {
    try {
      const response = await fetch(apiEndpoint, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      });
      const data = await response.json();
      return { status: response.status, data };
    } catch (err) {
      return { status: 0, error: err.message };
    }
  };

  console.log('➡️  Запрос 1 (Первичная отправка кода на веб)...');
  const res1 = await sendRequest();
  console.log(`[Запрос 1] HTTP ${res1.status}:`, res1.data);

  console.log('➡️  Запрос 2 (Мгновенный повтор)...');
  const res2 = await sendRequest();
  console.log(`[Запрос 2] HTTP ${res2.status}:`, res2.data);

  if (res2.status === 429 && (res2.data.code === 'COOLDOWN_ACTIVE' || res2.data.code === 'RATE_LIMIT_EXCEEDED' || res2.data.code === 'EMAIL_LIMIT_EXCEEDED')) {
    console.log(`%c🔒 УЯЗВИМОСТЬ ЗАКРЫТА! Запрос заблокирован (HTTP ${res2.status}). Код ошибки: ${res2.data.code}. Кулдаун: ${res2.data.retry_after || 60} сек.`, 'color: #10b981; font-weight: bold; font-size: 14px;');
  } else if (res2.status === 200) {
    console.log('%c🚨 УЯЗВИМОСТЬ ВСЁ ЕЩЁ АКТИВНА! Второй запрос прошёл без задержки!', 'color: #ef4444; font-weight: bold; font-size: 14px;');
  }
})();
