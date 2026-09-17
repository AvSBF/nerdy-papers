/* ============================================================
   Nerdy Papers — учебник по Godot
   Общий скрипт: навигация, оглавление, сворачивание разделов,
   чекбоксы «изучено», прогресс, подсветка GDScript, квизы.
   ============================================================ */

(function () {
  "use strict";

  /* ---------- Список глав и их разделов ---------- */

  var CHAPTERS = [
    { id: "01-unity-to-godot", num: "01", title: "Мышление Godot",
      desc: "Как понятия Unity (GameObject, Component, Prefab) переводятся в Godot (Node, Scene, PackedScene).",
      sections: [
        "Сцена — это дерево узлов", "Узлы вместо компонентов", "Сцены = префабы",
        "Скрипт живёт на узле", "Интерактив: переводчик понятий", "Проверь себя"
      ] },
    { id: "02-scene-tree", num: "02", title: "Дерево сцен и узлы",
      desc: "Разбираем Player.tscn, World.tscn и prefab-сцены этого проекта узел за узлом.",
      sections: [
        "Корневая сцена: World.tscn", "Сцена игрока: Player.tscn", "Слои коллизий",
        "Группы", "Интерактив: исследователь сцены", "Проверь себя"
      ] },
    { id: "03-gdscript", num: "03", title: "GDScript и сигналы",
      desc: "@export, @onready, жизненный цикл и сигналы вместо C#-событий.",
      sections: [
        "Синтаксис за 5 минут", "@export и @onready", "Жизненный цикл узла",
        "Сигналы", "Интерактив: как бежит сигнал", "Проверь себя"
      ] },
    { id: "04-player-movement", num: "04", title: "Движение игрока",
      desc: "CharacterBody3D, velocity, move_and_slide() и ввод с клавиатуры.",
      sections: [
        "CharacterBody3D", "Ввод: оси действий", "Разбор по шагам",
        "Интерактив: откуда берётся направление", "Проверь себя"
      ] },
    { id: "05-camera-look", num: "05", title: "Камера и обзор",
      desc: "Вращение камеры мышью, захват курсора и ограничение наклона (pitch).",
      sections: [
        "Весь файл целиком", "1. Захват курсора", "2. Ловим движение мыши",
        "3. Yaw — поворот тела", "4. Pitch — наклон камеры", "Интерактив: mouse look", "Проверь себя"
      ] },
    { id: "06-interaction", num: "06", title: "Взаимодействие",
      desc: "Группы, физический рейкаст из камеры и подсказки [E]/[G].",
      sections: [
        "Утилита рейкаста", "Interactor: мозг взаимодействия", "Подсказки в UI",
        "Интерактив: рейкаст из камеры", "Проверь себя"
      ] },
    { id: "07-paper-physics", num: "07", title: "Физика бумаги",
      desc: "RigidBody3D, _integrate_forces и ручной полёт бумаги в руку.",
      sections: [
        "RigidBody3D vs CharacterBody3D", "1. Страховка от падения под пол",
        "2. Подбор: выключаем физику", "3. Полёт в руку", "4. Удержание", "5. Бросок",
        "Интерактив: полёт бумаги в руку", "Проверь себя"
      ] },
    { id: "08-spawning-storage", num: "08", title: "Спавн и хранение",
      desc: "PackedScene.instantiate(), Area3D, счётчики и возврат чужой бумаги.",
      sections: [
        "1. Спавн: стол-раздатчик", "2. Кнопка: анимация и await",
        "3. Ящик: Area3D и сигнал body_entered", "Интерактив: ящики и типы", "Проверь себя"
      ] },
    { id: "09-ui-tweens", num: "09", title: "UI и твины",
      desc: "CanvasLayer, Control-узлы, твины, await и отладочное меню.",
      sections: [
        "CanvasLayer и Control", "Отладочное меню", "Твины",
        "Интерактив: кривые твинов", "Что дальше", "Проверь себя"
      ] },
    { id: "10-paper-outline", num: "10", title: "Окантовка бумаги (шейдер)",
      desc: "Белая окантовка при наведении: перевёрнутый корпус (inverted hull), cull_front и depth-test.",
      sections: [
        "Задача", "Ховер уже есть", "Идея: перевёрнутый корпус", "Шейдер: cull_front",
        "Узел Outline в сцене", "Скрипт paper_outline.gd", "Связка с ховером",
        "Интерактив: как это работает", "А если хочется сквозь стены?", "Проверь себя"
      ] }
  ];

  var KEY_CHAPTERS = "nerdy-papers-progress";
  var KEY_SECTIONS = "nerdy-papers-sections";
  var KEY_EXPANDED = "nerdy-papers-expanded";

  /* ---------- Хранилище ---------- */

  function load(key, fallback) {
    try {
      var raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (e) { return fallback; }
  }

  function save(key, value) {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch (e) { /* file:// */ }
  }

  function findChapter(id) {
    for (var i = 0; i < CHAPTERS.length; i++) if (CHAPTERS[i].id === id) return CHAPTERS[i];
    return null;
  }

  /* ---------- Прогресс по главам ---------- */

  function getDoneChapters() { return load(KEY_CHAPTERS, []); }
  function isDone(id) { return getDoneChapters().indexOf(id) !== -1; }

  function setDone(id, value) {
    var list = getDoneChapters();
    var i = list.indexOf(id);
    if (value && i === -1) list.push(id);
    if (!value && i !== -1) list.splice(i, 1);
    save(KEY_CHAPTERS, list);
    syncChapterDoneCheckbox();
    updateSideProgress();
  }

  /* ---------- Прогресс по разделам ---------- */

  function allSections() { return load(KEY_SECTIONS, {}); }

  function getSectionsDone(chapter) {
    var data = allSections();
    return data[chapter] || [];
  }

  function isSectionDone(chapter, section) {
    return getSectionsDone(chapter).indexOf(section) !== -1;
  }

  function setSectionDone(chapter, section, value) {
    var data = allSections();
    var list = data[chapter] || [];
    var i = list.indexOf(section);
    if (value && i === -1) list.push(section);
    if (!value && i !== -1) list.splice(i, 1);
    data[chapter] = list;
    save(KEY_SECTIONS, data);
  }

  /* ---------- Свёрнутые/развёрнутые пункты в сайдбаре ---------- */

  function getExpanded() { return load(KEY_EXPANDED, null); }
  function saveExpanded(list) { save(KEY_EXPANDED, list); }

  /* ---------- Slug ---------- */

  function slugify(text) {
    return String(text).toLowerCase()
      .replace(/[^\wа-яё\s-]/gi, "")
      .trim()
      .replace(/\s+/g, "-");
  }

  /* ---------- Сайдбар ---------- */

  function buildSidebar() {
    var nav = document.getElementById("chapter-nav");
    if (!nav) return;
    var current = document.body.dataset.chapter || "";
    var expanded = getExpanded();
    if (!expanded) expanded = [current];
    var html = "";

    for (var i = 0; i < CHAPTERS.length; i++) {
      var c = CHAPTERS[i];
      var cls = [];
      if (c.id === current) cls.push("active");
      if (isDone(c.id)) cls.push("done");
      var isOpen = expanded.indexOf(c.id) !== -1;

      html += '<div class="nav-item">' +
        '<button class="nav-toggle' + (isOpen ? " open" : "") + '" type="button" ' +
          'data-chapter="' + c.id + '" title="Свернуть / развернуть разделы">▸</button>' +
        '<a class="nav-link ' + cls.join(" ") + '" href="' + c.id + '.html">' +
          '<span class="num">' + c.num + '</span>' +
          '<span class="name">' + c.title + '</span></a>' +
        '<label class="nav-check" title="Отметить главу изученной">' +
          '<input type="checkbox" data-chapter="' + c.id + '"' + (isDone(c.id) ? " checked" : "") + '>' +
        '</label>' +
        '</div>';

      html += '<div class="nav-sections' + (isOpen ? " open" : "") + '" data-chapter="' + c.id + '">';
      for (var s = 0; s < c.sections.length; s++) {
        var secSlug = slugify(c.sections[s]);
        var secDone = isSectionDone(c.id, secSlug);
        html += '<a href="' + c.id + '.html#' + secSlug + '" class="' + (secDone ? "done" : "") + '">' +
          (secDone ? "✓ " : "") + c.sections[s] + '</a>';
      }
      html += "</div>";
    }
    nav.innerHTML = html;

    // чекбоксы глав
    Array.prototype.forEach.call(nav.querySelectorAll(".nav-check input"), function (cb) {
      cb.addEventListener("change", function () {
        setDone(cb.dataset.chapter, cb.checked);
        buildSidebar();
      });
    });

    // сворачивание пунктов
    Array.prototype.forEach.call(nav.querySelectorAll(".nav-toggle"), function (btn) {
      btn.addEventListener("click", function () {
        var id = btn.dataset.chapter;
        var list = getExpanded() || [current];
        var idx = list.indexOf(id);
        if (idx === -1) list.push(id); else list.splice(idx, 1);
        saveExpanded(list);
        buildSidebar();
      });
    });
  }

  /* ---------- Общий прогресс в сайдбаре ---------- */

  function buildSideProgress() {
    var sidebar = document.querySelector(".sidebar");
    var brand = sidebar ? sidebar.querySelector(".brand") : null;
    if (!brand || sidebar.querySelector(".side-progress")) return;
    var box = document.createElement("div");
    box.className = "side-progress";
    box.innerHTML =
      '<div class="label"><span>Прогресс курса</span><span class="pct">0%</span></div>' +
      '<div class="progress-bar"><i></i></div>';
    brand.parentNode.insertBefore(box, brand.nextSibling);
    updateSideProgress();
  }

  function updateSideProgress() {
    var box = document.querySelector(".side-progress");
    if (!box) return;
    var done = getDoneChapters().filter(function (id) { return findChapter(id); }).length;
    var pct = Math.round((done / CHAPTERS.length) * 100);
    box.querySelector(".pct").textContent = pct + "%";
    box.querySelector(".progress-bar > i").style.width = pct + "%";
  }

  /* ---------- Прогресс главы в контенте ---------- */

  function buildChapterProgress() {
    var chapter = document.body.dataset.chapter;
    var content = document.querySelector(".content");
    if (!chapter || !content) return;
    var ch = findChapter(chapter);
    if (!ch) return;
    var firstH2 = content.querySelector("h2");
    var box = document.createElement("div");
    box.className = "chapter-progress";
    box.id = "chapter-progress";
    box.innerHTML =
      '<div class="label"><span>Прогресс главы</span><span class="pct">0%</span></div>' +
      '<div class="progress-bar"><i></i></div>';
    if (firstH2) content.insertBefore(box, firstH2);
    else content.appendChild(box);
    updateChapterProgress();
  }

  function updateChapterProgress() {
    var chapter = document.body.dataset.chapter;
    var box = document.getElementById("chapter-progress");
    if (!chapter || !box) return;
    var ch = findChapter(chapter);
    if (!ch || !ch.sections.length) return;
    var done = getSectionsDone(chapter).length;
    var pct = Math.round((done / ch.sections.length) * 100);
    box.querySelector(".pct").textContent = done + " / " + ch.sections.length + " (" + pct + "%)";
    box.querySelector(".progress-bar > i").style.width = pct + "%";

    // все разделы изучены → глава автоматически считается пройденной
    if (done >= ch.sections.length && !isDone(chapter)) {
      setDone(chapter, true);
      buildSidebar();
      updateSideProgress();
    }
  }

  /* ---------- Сворачиваемые разделы ---------- */

  function setupSections() {
    var content = document.querySelector(".content");
    if (!content) return;
    var chapter = document.body.dataset.chapter || "";
    var heads = [];
    Array.prototype.forEach.call(content.children, function (el) {
      if (el.tagName === "H2") heads.push(el);
    });

    var usedIds = {};
    heads.forEach(function (h, i) {
      var base = slugify(h.textContent) || ("section-" + i);
      var id = base;
      var n = 2;
      while (usedIds[id]) { id = base + "-" + n; n++; }
      usedIds[id] = true;
      h.id = id;

      // оборачиваем всё до следующего h2 в сворачиваемое тело
      var next = heads[i + 1];
      var body = document.createElement("div");
      body.className = "section-body";
      var inner = document.createElement("div");
      inner.className = "section-inner";
      var node = h.nextSibling;
      while (node) {
        if (node === next) break;
        if (node.nodeType === 1 && (node.classList.contains("chapter-done") ||
            node.classList.contains("chapter-nav") || node.classList.contains("chapter-progress"))) break;
        var following = node.nextSibling;
        inner.appendChild(node);
        node = following;
      }
      body.appendChild(inner);
      h.parentNode.insertBefore(body, h.nextSibling);

      // заголовок: текст + чекбокс + шеврон
      h.classList.add("section-head");
      var title = document.createElement("span");
      title.className = "section-title-text";
      while (h.firstChild) title.appendChild(h.firstChild);
      h.appendChild(title);

      var label = document.createElement("label");
      label.className = "section-done";
      label.title = "Отметить раздел изученным";
      label.addEventListener("click", function (e) { e.stopPropagation(); });
      var cb = document.createElement("input");
      cb.type = "checkbox";
      cb.checked = isSectionDone(chapter, h.id);
      cb.addEventListener("click", function (e) { e.stopPropagation(); });
      cb.addEventListener("change", function (e) {
        e.stopPropagation();
        setSectionDone(chapter, h.id, cb.checked);
        h.classList.toggle("is-done", cb.checked);
        updateChapterProgress();
        buildSidebar();
        updateSideProgress();
      });
      if (cb.checked) h.classList.add("is-done");
      label.appendChild(cb);
      if (chapter) h.appendChild(label);

      var toggle = document.createElement("button");
      toggle.type = "button";
      toggle.className = "section-toggle";
      toggle.textContent = "▾";
      toggle.title = "Свернуть / развернуть раздел";
      toggle.addEventListener("click", function (e) {
        e.stopPropagation();
        body.classList.toggle("collapsed");
        h.classList.toggle("collapsed", body.classList.contains("collapsed"));
      });
      h.appendChild(toggle);

      h.addEventListener("click", function () {
        body.classList.toggle("collapsed");
        h.classList.toggle("collapsed", body.classList.contains("collapsed"));
      });
    });
  }

  /* ---------- Оглавление ---------- */

  function buildToc() {
    var toc = document.getElementById("toc");
    var content = document.querySelector(".content");
    if (!toc || !content) return;
    var heads = content.querySelectorAll("h2");
    if (!heads.length) { toc.style.display = "none"; return; }
    var html = '<div class="nav-title">На этой странице</div>';
    for (var i = 0; i < heads.length; i++) {
      var h = heads[i];
      var textEl = h.querySelector(".section-title-text");
      var text = textEl ? textEl.textContent : h.textContent;
      html += '<a href="#' + h.id + '">' + text + "</a>";
    }
    toc.innerHTML = html;

    var links = toc.querySelectorAll("a");
    if ("IntersectionObserver" in window) {
      var observer = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) {
            links.forEach(function (l) { l.classList.remove("active"); });
            var link = toc.querySelector('a[href="#' + e.target.id + '"]');
            if (link) link.classList.add("active");
          }
        });
      }, { rootMargin: "-10% 0px -75% 0px" });
      heads.forEach(function (h) { observer.observe(h); });
    }
  }

  /* ---------- Кнопки "предыдущая / следующая" ---------- */

  function buildChapterNav() {
    var box = document.querySelector("[data-auto-nav]");
    if (!box) return;
    var current = document.body.dataset.chapter || "";
    var idx = -1;
    for (var i = 0; i < CHAPTERS.length; i++) {
      if (CHAPTERS[i].id === current) { idx = i; break; }
    }
    var prev = idx > 0 ? CHAPTERS[idx - 1] : null;
    var next = idx >= 0 && idx < CHAPTERS.length - 1 ? CHAPTERS[idx + 1] : null;
    var html = "";
    if (prev) {
      html += '<a class="prev" href="' + prev.id + '.html"><span class="dir">← Назад</span>' +
        prev.num + ". " + prev.title + "</a>";
    } else {
      html += '<a class="prev ghost" href="#"></a>';
    }
    if (next) {
      html += '<a class="next" href="' + next.id + '.html"><span class="dir">Дальше →</span>' +
        next.num + ". " + next.title + "</a>";
    } else {
      html += '<a class="next" href="index.html"><span class="dir">Финиш →</span>К карте обучения</a>';
    }
    box.innerHTML = html;
  }

  /* ---------- Чекбокс "глава пройдена" внизу ---------- */

  function syncChapterDoneCheckbox() {
    var box = document.querySelector(".chapter-done input");
    var current = document.body.dataset.chapter;
    if (!box || !current) return;
    box.checked = isDone(current);
  }

  function wireDoneToggle() {
    var box = document.querySelector(".chapter-done input");
    var current = document.body.dataset.chapter;
    if (!box || !current) return;
    box.checked = isDone(current);
    box.addEventListener("change", function () {
      setDone(current, box.checked);
      buildSidebar();
      updateSideProgress();
    });
  }

  /* ---------- Хаб: прогресс и карточки ---------- */

  function buildHub() {
    var grid = document.getElementById("chapter-grid");
    if (!grid) return;
    var html = "";
    for (var i = 0; i < CHAPTERS.length; i++) {
      var c = CHAPTERS[i];
      var done = isDone(c.id);
      var secDone = getSectionsDone(c.id).length;
      var pct = Math.round((secDone / c.sections.length) * 100);
      html += '<a class="chapter-card' + (done ? " done" : "") + '" href="' + c.id + '.html">' +
        '<span class="k">Глава ' + c.num + "</span>" +
        "<h3>" + c.title + "</h3>" +
        "<p>" + c.desc + "</p>" +
        '<div class="progress-bar"><i style="width:' + pct + '%"></i></div>' +
        '<div class="card-meta">' + secDone + " / " + c.sections.length + " разделов изучено</div></a>";
    }
    grid.innerHTML = html;

    var done = getDoneChapters().filter(function (id) { return findChapter(id); }).length;
    var pct = Math.round((done / CHAPTERS.length) * 100);
    var bar = document.querySelector(".content .progress-bar > i");
    if (bar) bar.style.width = pct + "%";
    var label = document.getElementById("progress-label");
    if (label) label.textContent = done + " из " + CHAPTERS.length + " глав пройдено (" + pct + "%)";
  }

  /* ---------- Подсветка GDScript ---------- */

  var GD_RE = new RegExp([
    "(#[^\\n]*)",
    "(\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*')",
    "(@[A-Za-z_]\\w*)",
    "\\b(func|var|const|signal|class_name|extends|return|if|elif|else|for|while|match|break|continue|pass|and|or|not|in|is|as|await|static|enum|preload|load|super)\\b",
    "\\b(true|false|null|self)\\b",
    "\\b(\\d+\\.?\\d*(?:e[+-]?\\d+)?)\\b",
    "\\b([A-Z][A-Za-z0-9_]*)\\b",
    "([A-Za-z_]\\w*)(?=\\s*\\()"
  ].join("|"), "g");

  var GD_CLASSES = ["tok-com", "tok-str", "tok-ann", "tok-kw", "tok-bool", "tok-num", "tok-cls", "tok-fn"];

  function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  function highlightGD(code) {
    var out = "";
    var last = 0;
    var m;
    GD_RE.lastIndex = 0;
    while ((m = GD_RE.exec(code)) !== null) {
      if (m.index > last) out += escapeHtml(code.slice(last, m.index));
      var cls = null;
      for (var g = 1; g <= 8; g++) {
        if (m[g] !== undefined) { cls = GD_CLASSES[g - 1]; break; }
      }
      out += '<span class="' + cls + '">' + escapeHtml(m[0]) + "</span>";
      last = m.index + m[0].length;
      if (m[0].length === 0) GD_RE.lastIndex++;
    }
    out += escapeHtml(code.slice(last));
    return out;
  }

  function highlightAll() {
    var blocks = document.querySelectorAll("pre code[data-lang]");
    Array.prototype.forEach.call(blocks, function (b) {
      var lang = b.getAttribute("data-lang");
      var raw = b.textContent.replace(/^\n/, "").replace(/\s+$/, "");
      if (lang === "gdscript" || lang === "gd") {
        b.innerHTML = highlightGD(raw);
      } else {
        b.innerHTML = escapeHtml(raw);
      }
    });
  }

  /* ---------- Кнопки копирования ---------- */

  function wireCopyButtons() {
    var buttons = document.querySelectorAll(".copy-btn");
    Array.prototype.forEach.call(buttons, function (btn) {
      btn.addEventListener("click", function () {
        var block = btn.closest(".code");
        var code = block ? block.querySelector("code") : null;
        if (!code) return;
        var text = code.textContent;
        var done = function () {
          btn.textContent = "Скопировано ✓";
          btn.classList.add("ok");
          setTimeout(function () {
            btn.textContent = "Копировать";
            btn.classList.remove("ok");
          }, 1400);
        };
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(done, function () { fallbackCopy(text, done); });
        } else {
          fallbackCopy(text, done);
        }
      });
    });
  }

  function fallbackCopy(text, cb) {
    var ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand("copy"); cb(); } catch (e) { /* ignore */ }
    document.body.removeChild(ta);
  }

  /* ---------- Квизы ---------- */

  function wireQuizzes() {
    var quizzes = document.querySelectorAll(".quiz");
    Array.prototype.forEach.call(quizzes, function (quiz) {
      var opts = quiz.querySelectorAll(".opt");
      var feedback = quiz.querySelector(".quiz-feedback");
      Array.prototype.forEach.call(opts, function (opt) {
        opt.addEventListener("click", function () {
          if (quiz.dataset.answered === "1") return;
          quiz.dataset.answered = "1";
          var correct = opt.dataset.correct === "true";
          Array.prototype.forEach.call(opts, function (o) {
            o.disabled = true;
            if (o.dataset.correct === "true") o.classList.add("correct");
          });
          if (!correct) opt.classList.add("wrong");
          if (feedback) {
            feedback.classList.add("show", correct ? "good" : "bad");
            var text = correct ? (opt.dataset.explain || "Верно!") :
              (opt.dataset.explain || "Не совсем. Правильный вариант подсвечен зелёным.");
            feedback.innerHTML = (correct ? "<b>Верно.</b> " : "<b>Мимо.</b> ") + text;
          }
        });
      });
    });
  }

  /* ---------- Кнопка "наверх" ---------- */

  function wireBackTop() {
    var btn = document.querySelector(".back-top");
    if (!btn) return;
    window.addEventListener("scroll", function () {
      btn.classList.toggle("show", window.scrollY > 500);
    });
    btn.addEventListener("click", function () {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }

  /* ---------- Публичные утилиты для демо ---------- */

  function fitCanvas(canvas) {
    var dpr = window.devicePixelRatio || 1;
    var rect = canvas.getBoundingClientRect();
    var w = rect.width || canvas.clientWidth || 600;
    var h = parseFloat(canvas.getAttribute("data-h")) || 260;
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    canvas.style.height = h + "px";
    var ctx = canvas.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    return { ctx: ctx, w: w, h: h };
  }

  function loop(fn) {
    var last = performance.now();
    function frame(now) {
      var dt = Math.min(0.1, (now - last) / 1000);
      last = now;
      fn(dt, now);
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }

  function easeInOut(t) {
    return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
  }

  function arrow(ctx, x1, y1, x2, y2, color, width) {
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.lineWidth = width || 2;
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
    var ang = Math.atan2(y2 - y1, x2 - x1);
    var size = 7 + (width || 2);
    ctx.beginPath();
    ctx.moveTo(x2, y2);
    ctx.lineTo(x2 - size * Math.cos(ang - 0.4), y2 - size * Math.sin(ang - 0.4));
    ctx.lineTo(x2 - size * Math.cos(ang + 0.4), y2 - size * Math.sin(ang + 0.4));
    ctx.closePath();
    ctx.fill();
  }

  window.NP = {
    chapters: CHAPTERS,
    highlight: highlightGD,
    escapeHtml: escapeHtml,
    fitCanvas: fitCanvas,
    loop: loop,
    easeInOut: easeInOut,
    arrow: arrow,
    isDone: isDone,
    setDone: setDone,
    COLORS: {
      accent: "#478cbf", accent2: "#6cc4f2", green: "#7ee787",
      orange: "#ffa657", red: "#ff7b72", purple: "#d2a8ff",
      yellow: "#e3b341", muted: "#93a1b1", text: "#e6edf3"
    }
  };

  /* ---------- Запуск ---------- */

  document.addEventListener("DOMContentLoaded", function () {
    setupSections();
    buildToc();
    buildSidebar();
    buildSideProgress();
    buildChapterProgress();
    buildChapterNav();
    buildHub();
    highlightAll();
    wireCopyButtons();
    wireQuizzes();
    wireDoneToggle();
    wireBackTop();
  });
})();
