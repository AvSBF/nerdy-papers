/* ============================================================
   Nerdy Papers — общие помощники для интерактивов баффов
   Положите рядом с buff-demo.js; используется через window.BuffDemo
   ============================================================ */

window.BuffDemo = (function () {
  "use strict";

  function clear(view) {
    view.ctx.clearRect(0, 0, view.w, view.h);
  }

  function progress(view, cfg) {
    var ctx = view.ctx;
    var bw = Math.min(view.w * 0.72, 460);
    var bx = view.w / 2 - bw / 2;
    var by = cfg.y == null ? view.h / 2 - 12 : cfg.y;
    var max = cfg.max > 0 ? cfg.max : 1;
    var pct = Math.min(1, Math.max(0, cfg.value / max));
    ctx.fillStyle = "#1b2632";
    ctx.fillRect(bx, by, bw, 24);
    ctx.fillStyle = cfg.color || "#478cbf";
    ctx.fillRect(bx, by, bw * pct, 24);
    ctx.strokeStyle = "#465060";
    ctx.strokeRect(bx, by, bw, 24);
    ctx.fillStyle = "#93a1b1";
    ctx.font = "12px monospace";
    ctx.textAlign = "center";
    ctx.fillText(cfg.label || "", view.w / 2, by + 17);
    ctx.textAlign = "left";
  }

  function line(view, cfg) {
    var ctx = view.ctx;
    ctx.fillStyle = cfg.color || "#93a1b1";
    ctx.font = cfg.font || "13px system-ui";
    ctx.textAlign = "left";
    ctx.fillText(cfg.text, cfg.x, cfg.y);
  }

  return { clear: clear, progress: progress, line: line };
})();