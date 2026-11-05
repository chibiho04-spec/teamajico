/* Team ajico — 共通スクリプト（ライブラリなし） */
(function () {
  'use strict';

  // 今年を © に入れる
  var y = document.getElementById('year');
  if (y) y.textContent = String(new Date().getFullYear());

  // 検証用：URL に ?fs=150 を付けると文字サイズ150%で表示
  var m = location.search.match(/[?&]fs=(\d+)/);
  if (m) document.documentElement.style.fontSize = m[1] + '%';

  // Instagram 埋め込み（幅600px固定）を枠の幅に合わせて縮める
  function fitInstagram() {
    var frames = document.querySelectorAll('.insta__frame');
    for (var i = 0; i < frames.length; i++) {
      var f = frames[i];
      var w = f.clientWidth;
      var iframe = f.querySelector('iframe');
      if (!iframe) continue;
      var scale = Math.min(1, w / 600);
      iframe.style.transform = 'scale(' + scale + ')';
      f.style.height = Math.round(560 * scale) + 'px';
    }
  }
  fitInstagram();
  window.addEventListener('resize', fitInstagram);
  window.addEventListener('load', fitInstagram);

  // 作品写真の拡大表示（WORKS）。.js-lightbox が無いページでは何もしない
  function initLightbox() {
    var gallery = document.querySelector('.js-lightbox');
    if (!gallery) return;
    var links = Array.prototype.slice.call(gallery.querySelectorAll('a[href]'));
    if (!links.length) return;
    var current = 0;

    var lb = document.createElement('div');
    lb.className = 'lb';
    lb.setAttribute('role', 'dialog');
    lb.setAttribute('aria-modal', 'true');
    lb.setAttribute('aria-label', '作品写真の拡大表示');
    lb.hidden = true;
    lb.innerHTML =
      '<div class="lb__stage"><img class="lb__img" alt=""></div>' +
      '<div class="lb__bar">' +
        '<button type="button" class="lb__btn lb__prev" aria-label="前の写真">‹ 前へ</button>' +
        '<span class="lb__count" aria-live="polite"></span>' +
        '<button type="button" class="lb__btn lb__next" aria-label="次の写真">次へ ›</button>' +
        '<button type="button" class="lb__btn lb__close" aria-label="閉じる">× 閉じる</button>' +
      '</div>';
    document.body.appendChild(lb);

    var img = lb.querySelector('.lb__img');
    var count = lb.querySelector('.lb__count');

    function show(i) {
      current = (i + links.length) % links.length;
      var a = links[current];
      var thumb = a.querySelector('img');
      img.src = a.getAttribute('href');
      img.alt = thumb ? thumb.alt : '';
      count.textContent = (current + 1) + ' / ' + links.length;
    }
    function open(i) {
      show(i);
      lb.hidden = false;
      document.body.style.overflow = 'hidden';
      lb.querySelector('.lb__close').focus();
    }
    function close() {
      lb.hidden = true;
      document.body.style.overflow = '';
      links[current].focus();
    }

    links.forEach(function (a, i) {
      a.addEventListener('click', function (e) { e.preventDefault(); open(i); });
    });
    lb.querySelector('.lb__prev').addEventListener('click', function () { show(current - 1); });
    lb.querySelector('.lb__next').addEventListener('click', function () { show(current + 1); });
    lb.querySelector('.lb__close').addEventListener('click', close);
    lb.querySelector('.lb__stage').addEventListener('click', function (e) { if (e.target !== img) close(); });
    document.addEventListener('keydown', function (e) {
      if (lb.hidden) return;
      if (e.key === 'Escape') close();
      else if (e.key === 'ArrowLeft') show(current - 1);
      else if (e.key === 'ArrowRight') show(current + 1);
    });
    // 横スワイプで前後（40px以上）
    var sx = null;
    lb.addEventListener('touchstart', function (e) { sx = e.touches.length > 1 ? null : e.touches[0].clientX; }, { passive: true });
    lb.addEventListener('touchmove', function (e) { if (e.touches.length > 1) sx = null; }, { passive: true });   // 二本指（ピンチ）はスワイプ扱いしない
    lb.addEventListener('touchend', function (e) {
      if (sx === null) return;
      var dx = e.changedTouches[0].clientX - sx;
      sx = null;
      if (dx > 40) show(current - 1);
      else if (dx < -40) show(current + 1);
    }, { passive: true });

    // 検証用：URL に ?lb=16 を付けると16枚目を開いた状態で表示
    var lm = location.search.match(/[?&]lb=(\d+)/);
    if (lm) open(Math.max(0, Math.min(links.length - 1, parseInt(lm[1], 10) - 1)));
  }
  initLightbox();
})();
