/**
 * Облачный ИИ-ассистент для приложения «Список покупок».
 * Cloudflare Worker (бесплатный тариф: 100 000 запросов/день).
 *
 * Зачем сервер: ключ LLM-провайдера нельзя класть в приложение — его вытащат из APK.
 * Приложение шлёт сюда только категорию магазина и названия товаров (без личных данных).
 *
 * POST /  {category: "Строительный", items: ["Гвозди", "Краска"], lang: "ru"}
 *   ->    {suggestions: [{name: "Молоток", reason: "к гвоздям"}, ...]}
 */
const MODEL = 'claude-haiku-5-5';
const MAX_ITEMS = 40;

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return json({ error: 'POST only' }, 405);
    if (env.APP_TOKEN && request.headers.get('X-App-Token') !== env.APP_TOKEN) {
      return json({ error: 'forbidden' }, 403);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'bad json' }, 400);
    }
    const category = String(body.category || 'Магазин').slice(0, 40);
    const items = (Array.isArray(body.items) ? body.items : [])
      .map((x) => String(x).slice(0, 60))
      .slice(0, MAX_ITEMS);
    if (items.length === 0) return json({ suggestions: [] });

    // Кэш одинаковых запросов на сутки — экономит деньги на популярных списках.
    const cacheKey = new Request('https://cache.local/' + encodeURIComponent(category + '|' + [...items].sort().join(',')));
    const cache = caches.default;
    const cached = await cache.match(cacheKey);
    if (cached) return cached;

    const prompt =
      `Пользователь составляет список покупок для магазина «${category}». В списке: ${items.join(', ')}.\n` +
      `Предложи до 5 товаров, которые логично докупить к этому списку и которые человек мог забыть ` +
      `(например, к гвоздям — молоток, к краске — валик). Не повторяй товары из списка. ` +
      `Ответь ТОЛЬКО JSON-массивом вида [{"name":"Молоток","reason":"к гвоздям"}]. ` +
      `name — короткое название товара с заглавной буквы, reason — 2-4 слова.`;

    const resp = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: env.MODEL || MODEL,
        max_tokens: 300,
        messages: [{ role: 'user', content: prompt }],
      }),
    });
    if (!resp.ok) return json({ suggestions: [], error: 'llm ' + resp.status }, 200);

    const data = await resp.json();
    const text = (data.content || []).map((c) => c.text || '').join('');
    let suggestions = [];
    try {
      const match = text.match(/\[[\s\S]*\]/);
      suggestions = JSON.parse(match ? match[0] : '[]')
        .filter((s) => s && typeof s.name === 'string')
        .slice(0, 5)
        .map((s) => ({ name: s.name.slice(0, 60), reason: String(s.reason || 'совет ассистента').slice(0, 40) }));
    } catch {
      suggestions = [];
    }
    const out = json({ suggestions });
    out.headers.set('Cache-Control', 'max-age=86400');
    await cache.put(cacheKey, out.clone());
    return out;
  },
};

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}
