/**
 * Lightbox-style zoom for images and inline SVGs.
 *
 * Mark anything "zoomable" and clicking it (or pressing Enter/Space when
 * focused) pops it up full size over a backdrop.
 *
 * Usage in a blog post (Asciidoctor):
 *
 *   image::my-diagram.svg[Alt text,role="zoomable",width="100%"]
 *
 * Asciidoctor puts the "zoomable" class on the *wrapping* <div class="imageblock">,
 * not on the <img> itself, so the click target and the thing we zoom/clone
 * are not always the same element - see findZoomSource() below. The class
 * can also be put directly on an <img> or inline <svg> (e.g. hand-written
 * HAML) and this still works.
 */
(function () {
  'use strict';

  function ready(fn) {
    if (document.readyState !== 'loading') {
      fn();
    } else {
      document.addEventListener('DOMContentLoaded', fn);
    }
  }

  ready(function () {
    var backdrop = document.createElement('div');
    backdrop.className = 'zoom-backdrop';
    backdrop.setAttribute('role', 'dialog');
    backdrop.setAttribute('aria-modal', 'true');
    backdrop.setAttribute('aria-label', 'Zoomed image');

    var closeButton = document.createElement('button');
    closeButton.type = 'button';
    closeButton.className = 'zoom-backdrop-close';
    closeButton.setAttribute('aria-label', 'Close');
    closeButton.innerHTML = '&times;';

    document.body.appendChild(backdrop);

    var lastFocused = null;

    // Make every zoomable trigger keyboard-operable, since the Asciidoctor
    // "imageblock" wrapper is a plain <div> with no native interactivity.
    Array.prototype.forEach.call(document.querySelectorAll('.zoomable'), function (el) {
      if (!el.hasAttribute('tabindex')) {
        el.setAttribute('tabindex', '0');
      }
      if (!el.hasAttribute('role')) {
        el.setAttribute('role', 'button');
      }
      if (!el.hasAttribute('aria-label')) {
        var img = el.tagName.toLowerCase() === 'img' ? el : el.querySelector('img');
        var alt = img && img.alt;
        el.setAttribute('aria-label', alt ? 'Zoom image: ' + alt : 'Zoom image');
      }
    });

    function findZoomSource(trigger) {
      var tag = trigger.tagName.toLowerCase();
      if (tag === 'img' || tag === 'svg') {
        return trigger;
      }
      return trigger.querySelector('img, svg');
    }

    function openZoom(trigger) {
      var source = findZoomSource(trigger);
      if (!source) {
        return;
      }

      backdrop.innerHTML = '';
      backdrop.appendChild(closeButton);

      if (source.tagName.toLowerCase() === 'svg') {
        var clone = source.cloneNode(true);
        clone.classList.remove('zoomable');
        clone.removeAttribute('tabindex');
        clone.removeAttribute('role');
        backdrop.appendChild(clone);
      } else {
        var img = document.createElement('img');
        img.src = source.currentSrc || source.src;
        if (source.srcset) {
          img.srcset = source.srcset;
        }
        img.alt = source.alt || '';
        backdrop.appendChild(img);
      }

      lastFocused = document.activeElement;
      backdrop.classList.add('active');
      document.body.style.overflow = 'hidden';
      closeButton.focus();
    }

    function closeZoom() {
      if (!backdrop.classList.contains('active')) {
        return;
      }
      backdrop.classList.remove('active');
      document.body.style.overflow = '';
      if (lastFocused && typeof lastFocused.focus === 'function') {
        lastFocused.focus();
      }
      lastFocused = null;
    }

    document.addEventListener('click', function (e) {
      // Clicks inside the backdrop only close it when they land on the
      // backdrop itself or the close button - not on the zoomed content,
      // so people can still e.g. select/copy text or right-click-save it.
      if (backdrop.contains(e.target)) {
        if (e.target === backdrop || e.target === closeButton) {
          closeZoom();
        }
        return;
      }

      var trigger = e.target.closest('.zoomable');
      if (trigger) {
        e.preventDefault();
        openZoom(trigger);
      }
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && backdrop.classList.contains('active')) {
        closeZoom();
        return;
      }

      if (e.key === 'Enter' || e.key === ' ') {
        var trigger = document.activeElement && document.activeElement.closest && document.activeElement.closest('.zoomable');
        if (trigger && !backdrop.contains(trigger)) {
          e.preventDefault();
          openZoom(trigger);
        }
      }
    });
  });
})();
