import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main(List<String> args) {
  final outPath = args.isNotEmpty ? args.first : 'assets/images/app_icon.png';
  final file = File(outPath);

  // 1024x1024 is a good source size for launcher icon generators.
  const size = 1024;
  final canvas = img.Image(width: size, height: size, numChannels: 4);

  // --- Background: deep charcoal with subtle radial vignette ---
  final center = (size - 1) / 2.0;
  final maxR = math.sqrt(2) * center;

  final bgInner = img.ColorRgba8(0x12, 0x13, 0x18, 0xFF); // #121318
  final bgOuter = img.ColorRgba8(0x0E, 0x0F, 0x12, 0xFF); // #0E0F12

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      final r = math.sqrt(dx * dx + dy * dy);
      final t = (r / maxR).clamp(0.0, 1.0);
      final t2 = math.pow(t, 1.6).toDouble();
      final c = _lerpColor(bgInner, bgOuter, t2);
      canvas.setPixel(x, y, c);
    }
  }

  // --- Optional outline: rounded square, subtle silver ---
  final outline = img.ColorRgba8(0xE8, 0xEA, 0xF0, (0.20 * 255).round());
  _drawRoundedRectStroke(
    canvas,
    x: 120,
    y: 120,
    w: size - 240,
    h: size - 240,
    r: 180,
    stroke: 18,
    color: outline,
  );

  // --- Monogram: interlocking "I" and "M" made from strokes ---
  // We draw on an overlay to add a soft glow.
  final overlay = img.Image(width: size, height: size, numChannels: 4);

  // Gradient endpoints (teal -> electric blue).
  final g0 = img.ColorRgba8(0x18, 0xE0, 0xC6, 0xFF);
  final g1 = img.ColorRgba8(0x3A, 0x7B, 0xFF, 0xFF);

  // Geometry settings.
  final monogramTop = 290;
  final monogramBottom = 760;
  final monogramLeft = 300;
  final monogramRight = 740;
  const stroke = 78; // thick, icon-friendly stroke

  // Left "I" stroke.
  _drawGradientCapsule(
    overlay,
    x0: monogramLeft,
    y0: monogramTop,
    x1: monogramLeft,
    y1: monogramBottom,
    radius: stroke / 2,
    g0: g0,
    g1: g1,
  );

  // "M" as two diagonals meeting + right vertical, interlocking with I.
  _drawGradientCapsule(
    overlay,
    x0: monogramLeft + 40,
    y0: monogramTop,
    x1: (monogramLeft + monogramRight) ~/ 2,
    y1: monogramBottom,
    radius: stroke / 2,
    g0: g0,
    g1: g1,
  );
  _drawGradientCapsule(
    overlay,
    x0: (monogramLeft + monogramRight) ~/ 2,
    y0: monogramBottom,
    x1: monogramRight - 40,
    y1: monogramTop,
    radius: stroke / 2,
    g0: g0,
    g1: g1,
  );
  _drawGradientCapsule(
    overlay,
    x0: monogramRight,
    y0: monogramTop,
    x1: monogramRight,
    y1: monogramBottom,
    radius: stroke / 2,
    g0: g0,
    g1: g1,
  );

  // Small "match" node in the center to suggest connection.
  final nodeX = ((monogramLeft + monogramRight) / 2).round();
  final nodeY = ((monogramTop + monogramBottom) / 2).round();
  _fillCircle(overlay, nodeX, nodeY, 52, img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xEE));
  _fillCircle(
    overlay,
    nodeX,
    nodeY,
    30,
    _lerpColor(g0, g1, 0.55),
  );

  // Glow: blur overlay and screen-blend.
  final glow = img.gaussianBlur(img.copyResize(overlay, width: size, height: size), radius: 14);
  _screenBlend(canvas, glow, opacity: 0.45);

  // Main monogram over the glow.
  img.compositeImage(canvas, overlay);

  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(canvas, level: 6));
  stdout.writeln('Wrote $outPath');
}

img.Color _lerpColor(img.Color a, img.Color b, double t) {
  int lerp(int x, int y) => (x + (y - x) * t).round().clamp(0, 255);
  return img.ColorRgba8(
    lerp(a.r.toInt(), b.r.toInt()),
    lerp(a.g.toInt(), b.g.toInt()),
    lerp(a.b.toInt(), b.b.toInt()),
    lerp(a.a.toInt(), b.a.toInt()),
  );
}

void _drawRoundedRectStroke(
  img.Image dst, {
  required int x,
  required int y,
  required int w,
  required int h,
  required int r,
  required int stroke,
  required img.Color color,
}) {
  // Approximate a rounded-rect stroke by drawing two filled rounded rects and
  // subtracting the inner one (via alpha overwrite).
  final outer = img.Image(width: dst.width, height: dst.height, numChannels: 4);
  final inner = img.Image(width: dst.width, height: dst.height, numChannels: 4);

  _fillRoundedRect(outer, x, y, w, h, r, color);
  _fillRoundedRect(inner, x + stroke, y + stroke, w - 2 * stroke, h - 2 * stroke, r - stroke, img.ColorRgba8(0, 0, 0, 0));

  // Clear inner area.
  for (var yy = 0; yy < dst.height; yy++) {
    for (var xx = 0; xx < dst.width; xx++) {
      final o = outer.getPixel(xx, yy);
      if (o.a > 0) {
        // If inside the inner rect, zero alpha; else keep.
        final isInner = _isInsideRoundedRect(xx, yy, x + stroke, y + stroke, w - 2 * stroke, h - 2 * stroke, r - stroke);
        if (!isInner) {
          dst.setPixel(xx, yy, o);
        }
      }
    }
  }
}

void _fillRoundedRect(img.Image dst, int x, int y, int w, int h, int r, img.Color color) {
  for (var yy = y; yy < y + h; yy++) {
    for (var xx = x; xx < x + w; xx++) {
      if (_isInsideRoundedRect(xx, yy, x, y, w, h, r)) {
        dst.setPixel(xx, yy, color);
      }
    }
  }
}

bool _isInsideRoundedRect(int px, int py, int x, int y, int w, int h, int r) {
  // Fast path: inside bounding box of center rectangle.
  final left = x + r;
  final right = x + w - r - 1;
  final top = y + r;
  final bottom = y + h - r - 1;
  if (px >= left && px <= right && py >= y && py <= y + h - 1) return true;
  if (px >= x && px <= x + w - 1 && py >= top && py <= bottom) return true;

  // Corner checks.
  final r2 = r * r;
  int dx, dy;

  // Top-left
  if (px < left && py < top) {
    dx = px - left;
    dy = py - top;
    return dx * dx + dy * dy <= r2;
  }
  // Top-right
  if (px > right && py < top) {
    dx = px - right;
    dy = py - top;
    return dx * dx + dy * dy <= r2;
  }
  // Bottom-left
  if (px < left && py > bottom) {
    dx = px - left;
    dy = py - bottom;
    return dx * dx + dy * dy <= r2;
  }
  // Bottom-right
  if (px > right && py > bottom) {
    dx = px - right;
    dy = py - bottom;
    return dx * dx + dy * dy <= r2;
  }

  return false;
}

void _fillCircle(img.Image dst, int cx, int cy, int radius, img.Color color) {
  final r2 = radius * radius;
  for (var y = cy - radius; y <= cy + radius; y++) {
    if (y < 0 || y >= dst.height) continue;
    for (var x = cx - radius; x <= cx + radius; x++) {
      if (x < 0 || x >= dst.width) continue;
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= r2) {
        dst.setPixel(x, y, color);
      }
    }
  }
}

void _drawGradientCapsule(
  img.Image dst, {
  required int x0,
  required int y0,
  required int x1,
  required int y1,
  required double radius,
  required img.Color g0,
  required img.Color g1,
}) {
  // Rasterize a thick line by sampling distance to segment.
  final minX = math.min(x0, x1) - radius.ceil() - 2;
  final maxX = math.max(x0, x1) + radius.ceil() + 2;
  final minY = math.min(y0, y1) - radius.ceil() - 2;
  final maxY = math.max(y0, y1) + radius.ceil() + 2;

  final vx = (x1 - x0).toDouble();
  final vy = (y1 - y0).toDouble();
  final len2 = vx * vx + vy * vy;

  for (var y = minY; y <= maxY; y++) {
    if (y < 0 || y >= dst.height) continue;
    for (var x = minX; x <= maxX; x++) {
      if (x < 0 || x >= dst.width) continue;

      // Project point onto segment [0,1].
      final wx = (x - x0).toDouble();
      final wy = (y - y0).toDouble();
      final t = (len2 == 0) ? 0.0 : ((wx * vx + wy * vy) / len2).clamp(0.0, 1.0);
      final px = x0 + t * vx;
      final py = y0 + t * vy;
      final dx = x - px;
      final dy = y - py;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist <= radius) {
        // Soft edge.
        final edge = (1.0 - (dist / radius)).clamp(0.0, 1.0);
        final aa = math.pow(edge, 1.8).toDouble();
        final c = _lerpColor(g0, g1, t);
        final out = img.ColorRgba8(c.r.toInt(), c.g.toInt(), c.b.toInt(), (aa * 255).round());

        // Alpha composite over existing.
        final under = dst.getPixel(x, y);
        dst.setPixel(x, y, _alphaOver(under, out));
      }
    }
  }
}

img.Color _alphaOver(img.Color under, img.Color over) {
  final oa = over.a / 255.0;
  final ua = under.a / 255.0;
  final outA = oa + ua * (1 - oa);
  if (outA <= 0) return img.ColorRgba8(0, 0, 0, 0);

  int comp(int u, int o) {
    final out = (o * oa + u * ua * (1 - oa)) / outA;
    return out.round().clamp(0, 255);
  }

  return img.ColorRgba8(
    comp(under.r.toInt(), over.r.toInt()),
    comp(under.g.toInt(), over.g.toInt()),
    comp(under.b.toInt(), over.b.toInt()),
    (outA * 255).round().clamp(0, 255),
  );
}

void _screenBlend(img.Image base, img.Image top, {required double opacity}) {
  final op = opacity.clamp(0.0, 1.0);
  for (var y = 0; y < base.height; y++) {
    for (var x = 0; x < base.width; x++) {
      final b = base.getPixel(x, y);
      final t = top.getPixel(x, y);
      if (t.a == 0) continue;

      // Screen blend per-channel with opacity.
      int screen(int cb, int ct) => 255 - (((255 - cb) * (255 - ct)) ~/ 255);
      final r = screen(b.r.toInt(), t.r.toInt());
      final g = screen(b.g.toInt(), t.g.toInt());
      final bb = screen(b.b.toInt(), t.b.toInt());

      final blended = img.ColorRgba8(r, g, bb, 255);
      final over = img.ColorRgba8(
        blended.r.toInt(),
        blended.g.toInt(),
        blended.b.toInt(),
        (op * t.a).round().clamp(0, 255),
      );

      base.setPixel(x, y, _alphaOver(b, over));
    }
  }
}

