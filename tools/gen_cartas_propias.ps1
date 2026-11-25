# Regenera las cartas de obra propia de la baraja (assets/cards y docs/cartas).
#
# Que genera (todo dibujado por codigo, sin copiar nada de terceros):
#   - oros_1 .. oros_9: la moneda propia (rosetón) con la distribucion habitual.
#   - oros_10 y oros_12: se conserva la figura de la baraja de Commons y solo se
#     sustituye la moneda de la esquina por la propia.
#   - bastos_11, copas_11, espadas_11, oros_11: caballo con jinete propio.
#
# Lo que NO toca: marco, esquinas redondeadas y numeros de cada carta (se
# conservan del PNG existente), las demas cartas y reverso.png.
#
# Uso (desde la raiz del repo, Windows PowerShell 5.1):
#   powershell -ExecutionPolicy Bypass -File tools\gen_cartas_propias.ps1
#   powershell -ExecutionPolicy Bypass -File tools\gen_cartas_propias.ps1 -Salida C:\ruta\prueba
#       (con -Salida solo escribe ahi, sin tocar el repo; ademas crea hoja.png)
#
# Es idempotente: el fondo se estima como mediana de las cartas de copas,
# espadas y bastos que no se regeneran, y las cartas regeneradas se vuelven a
# dibujar sobre ese fondo, asi que ejecutarlo dos veces da el mismo resultado.
# Si cambias las cartas, vuelve a copiar assets/cards a docs/cartas (lo hace el
# propio script cuando no se usa -Salida).
param(
    [string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$Salida = ''
)

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class CartasPropias
{
    const int W = 300, H = 460;
    // Interior del marco: [X0,X1) x [Y0,Y1). El marco ocupa x/y = 21..22 y 277/437..278.
    const int X0 = 24, X1 = 276, Y0 = 24, Y1 = 436;

    static Color C(string h) { return ColorTranslator.FromHtml(h); }
    // Paleta de la baraja (Tango, la misma de las cartas existentes).
    static readonly Color Ink = C("#2E3436");
    static readonly Color Gold = C("#EDD400");
    static readonly Color GoldLight = C("#FCE94F");
    static readonly Color GoldDark = C("#C4A000");
    static readonly Color Red = C("#CC0000");
    static readonly Color RedDark = C("#A40000");
    static readonly Color Blue = C("#3465A4");
    static readonly Color BlueLight = C("#729FCF");
    static readonly Color BlueDark = C("#204A87");
    static readonly Color Green = C("#4E9A06");
    static readonly Color GreenLight = C("#8AE234");
    static readonly Color GreenDark = C("#2F5E04");
    static readonly Color Skin = C("#F5C9A0");

    // ---------- E/S ----------
    static int[] Px(Bitmap b)
    {
        var d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int[] a = new int[W * H];
        Marshal.Copy(d.Scan0, a, 0, a.Length);
        b.UnlockBits(d);
        return a;
    }
    static void SetPx(Bitmap b, int[] a)
    {
        var d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        Marshal.Copy(a, 0, d.Scan0, a.Length);
        b.UnlockBits(d);
    }
    static Bitmap Load(string p)
    {
        byte[] by = File.ReadAllBytes(p);
        using (var ms = new MemoryStream(by))
        using (var s = new Bitmap(ms))
        {
            if (s.Width != W || s.Height != H) throw new Exception(p + ": se esperaba 300x460");
            var r = new Bitmap(W, H, PixelFormat.Format32bppArgb);
            SetPx(r, Px(s));
            r.SetResolution(96, 96);
            return r;
        }
    }

    // ---------- fondo ----------
    static int[] BuildBg(string dir)
    {
        var all = new List<int[]>();
        foreach (string s in new string[] { "copas", "espadas", "bastos" })
            foreach (int n in new int[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12 })
                using (var b = Load(Path.Combine(dir, s + "_" + n + ".png"))) all.Add(Px(b));
        int[] bg = new int[W * H];
        var vals = new List<int>();
        for (int y = Y0; y < Y1; y++)
            for (int x = X0; x < X1; x++)
            {
                vals.Clear();
                foreach (int[] a in all)
                {
                    int p = a[y * W + x];
                    int al = (p >> 24) & 255, r = (p >> 16) & 255, g = (p >> 8) & 255, bl = p & 255;
                    if (al == 255 && r >= 236 && Math.Abs(r - g) <= 2 && Math.Abs(g - bl) <= 2) vals.Add(r);
                }
                if (vals.Count == 0) { bg[y * W + x] = 0; continue; }
                vals.Sort();
                int v = vals[vals.Count / 2];
                bg[y * W + x] = unchecked((int)0xFF000000) | (v << 16) | (v << 8) | v;
            }
        // Huecos (sin ningun valor valido): copiar del vecino de la izquierda o de arriba.
        for (int y = Y0; y < Y1; y++)
            for (int x = X0; x < X1; x++)
                if (bg[y * W + x] == 0)
                    bg[y * W + x] = (x > X0 && bg[y * W + x - 1] != 0) ? bg[y * W + x - 1] : bg[(y - 1) * W + x];
        return bg;
    }

    // Borra el interior (a fondo) conservando los numeros de esquina.
    static void ClearInterior(Bitmap card, int[] bg, bool twoDigits, float[] pips)
    {
        int[] a = Px(card);
        int tlx1 = twoDigits ? 60 : 44, brx0 = twoDigits ? 240 : 256;
        for (int y = Y0; y < Y1; y++)
            for (int x = X0; x < X1; x++)
            {
                bool keepTL = x < tlx1 && y < 56;
                bool keepBR = x >= brx0 && y >= 404;
                if (keepTL || keepBR)
                {
                    // lo que caiga dentro de una moneda se borra: se vuelve a dibujar entero (idempotencia)
                    bool inCoin = false;
                    if (pips != null)
                        for (int k = 0; k < pips.Length; k += 3)
                        {
                            float dx = x + 0.5f - pips[k], dy = y + 0.5f - pips[k + 1], rr = pips[k + 2] / 2f + 3f;
                            if (dx * dx + dy * dy <= rr * rr) inCoin = true;
                        }
                    if (!inCoin) continue;
                }
                a[y * W + x] = bg[y * W + x];
            }
        SetPx(card, a);
    }

    // Borra un disco (a fondo), para sustituir una moneda sin tocar lo de al lado.
    static void ClearDisc(Bitmap card, int[] bg, float cx, float cy, float r)
    {
        int[] a = Px(card);
        for (int y = Y0; y < Y1; y++)
            for (int x = X0; x < X1; x++)
            {
                float dx = x + 0.5f - cx, dy = y + 0.5f - cy;
                if (dx * dx + dy * dy <= r * r) a[y * W + x] = bg[y * W + x];
            }
        SetPx(card, a);
    }

    static Graphics Gfx(Bitmap b)
    {
        var g = Graphics.FromImage(b);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
        g.SetClip(new Rectangle(X0, Y0, X1 - X0, Y1 - Y0));
        return g;
    }

    static Pen P(Color c, float w)
    {
        var p = new Pen(c, w);
        p.LineJoin = LineJoin.Round; p.StartCap = LineCap.Round; p.EndCap = LineCap.Round;
        return p;
    }
    static Color Mix(Color a, Color b, float t)
    {
        return Color.FromArgb(255, (int)(a.R + (b.R - a.R) * t), (int)(a.G + (b.G - a.G) * t), (int)(a.B + (b.B - a.B) * t));
    }
    static PointF[] Pts(params float[] v)
    {
        var r = new PointF[v.Length / 2];
        for (int i = 0; i < r.Length; i++) r[i] = new PointF(v[2 * i], v[2 * i + 1]);
        return r;
    }
    static void Ell(Graphics g, Color fill, Color ink, float lw, float cx, float cy, float rx, float ry)
    {
        using (var b = new SolidBrush(fill)) g.FillEllipse(b, cx - rx, cy - ry, 2 * rx, 2 * ry);
        if (lw > 0) using (var p = P(ink, lw)) g.DrawEllipse(p, cx - rx, cy - ry, 2 * rx, 2 * ry);
    }
    static void Poly(Graphics g, Color fill, Color ink, float lw, PointF[] pts)
    {
        using (var b = new SolidBrush(fill)) g.FillPolygon(b, pts);
        if (lw > 0) using (var p = P(ink, lw)) g.DrawPolygon(p, pts);
    }
    static void Curve(Graphics g, Color fill, Color ink, float lw, PointF[] pts, float tension)
    {
        using (var b = new SolidBrush(fill)) g.FillClosedCurve(b, pts, FillMode.Winding, tension);
        if (lw > 0) using (var p = P(ink, lw)) g.DrawClosedCurve(p, pts, tension, FillMode.Winding);
    }
    // Trazo grueso con contorno (patas, brazos, cola...).
    static void Limb(Graphics g, Color fill, float w, float lw, float tension, params float[] v)
    {
        PointF[] pts = Pts(v);
        using (var p = P(Ink, w + 2 * lw)) g.DrawCurve(p, pts, tension);
        using (var p = P(fill, w)) g.DrawCurve(p, pts, tension);
    }

    // ---------- moneda propia ----------
    // Disco dorado con aro perlado y rosetón de 8 puntas. Nada de logos ni escudos.
    public static void Coin(Graphics g, float cx, float cy, float r)
    {
        float lw = Math.Max(1.4f, r * 0.045f);
        Ell(g, Gold, Ink, lw, cx, cy, r, r);
        // aro interior
        using (var p = P(GoldDark, Math.Max(1.2f, r * 0.05f))) g.DrawEllipse(p, cx - r * 0.80f, cy - r * 0.80f, r * 1.6f, r * 1.6f);
        // perlas entre el borde y el aro
        for (int k = 0; k < 20; k++)
        {
            double a = k * Math.PI * 2 / 20;
            float px = cx + (float)Math.Cos(a) * r * 0.90f, py = cy + (float)Math.Sin(a) * r * 0.90f;
            Ell(g, GoldDark, Ink, 0, px, py, r * 0.034f, r * 0.034f);
        }
        // rosetón: estrella de 8 puntas
        var star = new PointF[16];
        for (int k = 0; k < 16; k++)
        {
            double a = -Math.PI / 2 + k * Math.PI / 8;
            float rad = (k % 2 == 0) ? r * 0.66f : r * 0.30f;
            star[k] = new PointF(cx + (float)Math.Cos(a) * rad, cy + (float)Math.Sin(a) * rad);
        }
        Poly(g, GoldDark, Ink, Math.Max(1f, r * 0.03f), star);
        Ell(g, GoldLight, GoldDark, Math.Max(1f, r * 0.04f), cx, cy, r * 0.22f, r * 0.22f);
        Ell(g, Gold, GoldDark, 0, cx, cy, r * 0.09f, r * 0.09f);
        // brillo
        using (var p = P(Color.FromArgb(150, 255, 255, 220), Math.Max(1.2f, r * 0.05f)))
            g.DrawArc(p, cx - r * 0.93f, cy - r * 0.93f, r * 1.86f, r * 1.86f, 200, 55);
    }

    // As de oros: moneda grande, laurel y cinta con el nombre de la app.
    static void AsDeOros(Graphics g)
    {
        float cx = 150, cy = 196, r = 92;
        // laurel (dos ramas desde abajo)
        float R2 = r + 9;
        const float a0 = 0.12f, da = 0.185f;
        const int nLeaf = 9;
        for (int side = -1; side <= 1; side += 2)
        {
            // tallo: arco desde abajo hacia arriba por cada lado
            float d0 = 90 + side * a0 * 57.2958f, d1 = 90 + side * (a0 + (nLeaf - 1) * da) * 57.2958f;
            using (var p = P(GreenDark, 2.6f))
                g.DrawArc(p, cx - R2, cy - R2, 2 * R2, 2 * R2, Math.Min(d0, d1), Math.Abs(d1 - d0));
            for (int k = 0; k < nLeaf; k++)
            {
                double a = Math.PI / 2 + side * (a0 + k * da);
                float nx = (float)Math.Cos(a), ny = (float)Math.Sin(a);       // hacia fuera
                float tx = side * -ny, ty = side * nx;                          // tangente hacia arriba
                float lx = cx + nx * R2, ly = cy + ny * R2;
                for (int o = 0; o < 2; o++)
                {
                    float sg = (o == 0) ? 1f : -1f;                             // fuera / dentro
                    float c35 = 0.82f, s35 = 0.57f;
                    float dx = tx * c35 + nx * s35 * sg, dy = ty * c35 + ny * s35 * sg;
                    float phi = (float)(Math.Atan2(dx, -dy) * 180 / Math.PI);
                    float len = 25f - k * 0.6f;
                    var st = g.Save();
                    g.TranslateTransform(lx, ly);
                    g.RotateTransform(phi);
                    Color lc = (o == 0) ? Green : Mix(Green, GreenLight, 0.4f);
                    var leaf = Pts(0, 0, len * 0.26f, -len * 0.38f, 0, -len, -len * 0.26f, -len * 0.38f);
                    using (var b = new SolidBrush(lc)) g.FillClosedCurve(b, leaf, FillMode.Winding, 0.6f);
                    using (var p = P(GreenDark, 1.3f)) g.DrawClosedCurve(p, leaf, 0.6f, FillMode.Winding);
                    g.Restore(st);
                }
            }
        }
        Coin(g, cx, cy, r);
        // cinta
        float by = 352;
        var tailL = Pts(40, by + 4, 78, by + 4, 78, by + 40, 40, by + 40, 54, by + 22);
        var tailR = Pts(260, by + 4, 222, by + 4, 222, by + 40, 260, by + 40, 246, by + 22);
        Poly(g, RedDark, Ink, 1.6f, tailL);
        Poly(g, RedDark, Ink, 1.6f, tailR);
        var band = Pts(70, by - 6, 230, by - 6, 230, by + 30, 70, by + 30);
        Poly(g, Red, Ink, 1.8f, band);
        using (var p = P(Color.FromArgb(120, 255, 255, 255), 1.4f)) g.DrawLine(p, 76, by - 2, 224, by - 2);
        using (var f = new Font("Arial", 19f, FontStyle.Bold, GraphicsUnit.Pixel))
        using (var sf = new StringFormat())
        {
            sf.Alignment = StringAlignment.Center; sf.LineAlignment = StringAlignment.Center;
            var rc = new RectangleF(70, by - 6, 160, 36);
            using (var b = new SolidBrush(Ink)) g.DrawString("PADDOCK", f, b, new RectangleF(rc.X + 1, rc.Y + 1.2f, rc.Width, rc.Height), sf);
            g.DrawString("PADDOCK", f, Brushes.White, rc, sf);
        }
        // estrella superior
        var st5 = new PointF[10];
        for (int k = 0; k < 10; k++)
        {
            double a = -Math.PI / 2 + k * Math.PI / 5;
            float rad = (k % 2 == 0) ? 17 : 7.5f;
            st5[k] = new PointF(150 + (float)Math.Cos(a) * rad, 66 + (float)Math.Sin(a) * rad);
        }
        Poly(g, Gold, Ink, 1.6f, st5);
    }

    // ---------- simbolos de palo (propios) ----------
    // Todos se dibujan en un espacio local de unos 100 de alto, centrados en (0,0).
    static void Cup(Graphics g)
    {
        // pie
        Poly(g, Gold, Ink, 1.6f, Pts(-24, 48, 24, 48, 15, 33, -15, 33));
        // tallo y nudo
        using (var b = new SolidBrush(Gold)) g.FillRectangle(b, -4.5f, 4, 9, 30);
        using (var p = P(Ink, 1.6f)) { g.DrawLine(p, -4.5f, 6, -4.5f, 33); g.DrawLine(p, 4.5f, 6, 4.5f, 33); }
        Ell(g, GoldLight, Ink, 1.6f, 0, 20, 10, 5.5f);
        // copa
        var bowl = new GraphicsPath();
        bowl.AddLine(-34, -42, 34, -42);
        bowl.AddBezier(34, -42, 34, -8, 20, 4, 7, 6);
        bowl.AddLine(7, 6, -7, 6);
        bowl.AddBezier(-7, 6, -20, 4, -34, -8, -34, -42);
        bowl.CloseFigure();
        using (var b = new SolidBrush(Red)) g.FillPath(b, bowl);
        using (var p = P(Ink, 1.8f)) g.DrawPath(p, bowl);
        // brillo y aro dorado
        using (var p = P(Color.FromArgb(150, 255, 160, 160), 3.5f)) g.DrawBezier(p, -24, -36, -25, -18, -17, -4, -10, 0);
        Poly(g, Gold, Ink, 1.6f, Pts(-37, -52, 37, -52, 34, -40, -34, -40));
        // joyas
        for (int k = -2; k <= 2; k++) Ell(g, GoldLight, Ink, 1f, k * 12, -26, 3.4f, 4.6f);
    }

    static void Sword(Graphics g)
    {
        // hoja apuntando arriba
        Poly(g, BlueLight, Ink, 1.7f, Pts(-5.5f, -10, 5.5f, -10, 4.5f, -86, 0, -100, -4.5f, -86));
        using (var p = P(Color.FromArgb(200, 235, 245, 255), 2f)) g.DrawLine(p, -1.2f, -14, -1.2f, -84);
        using (var p = P(BlueDark, 1.2f)) g.DrawLine(p, 1.8f, -14, 1.8f, -84);
        // guarda
        Poly(g, Gold, Ink, 1.7f, Pts(-24, -14, 24, -14, 24, -6, -24, -6));
        Ell(g, Gold, Ink, 1.5f, -24, -10, 4.5f, 5f);
        Ell(g, Gold, Ink, 1.5f, 24, -10, 4.5f, 5f);
        // empuñadura y pomo
        Poly(g, RedDark, Ink, 1.6f, Pts(-4, -6, 4, -6, 4, 22, -4, 22));
        Ell(g, Gold, Ink, 1.6f, 0, 27, 6.5f, 6.5f);
    }

    static void Club(Graphics g)
    {
        // basto (garrote nudoso): cabeza gruesa y redondeada, mango fino. Apunta arriba.
        PointF[] body = Pts(-4.5f, 50, -5, 24, -9, 0, -15, -26, -18, -54, -14, -80, 0, -92, 14, -80, 18, -54, 15, -26, 9, 0, 5, 24, 4.5f, 50);
        var gp = new GraphicsPath(); gp.AddClosedCurve(body, 0.45f);
        // nudos que sobresalen del contorno (rama cortada)
        Ell(g, GreenDark, Ink, 1.6f, -19, -40, 5.5f, 6.5f);
        Ell(g, GreenDark, Ink, 1.6f, 20, -64, 5.5f, 6.5f);
        Ell(g, GreenDark, Ink, 1.6f, 10, -12, 4.5f, 5f);
        using (var b = new SolidBrush(Green)) g.FillPath(b, gp);
        using (var p = P(Ink, 1.8f)) g.DrawPath(p, gp);
        using (var p = P(Color.FromArgb(150, 138, 226, 52), 3.2f)) g.DrawCurve(p, Pts(-8, 18, -9, -8, -12, -36, -10, -64, -5, -80), 0.5f);
        // vetas
        using (var p = P(GreenDark, 1.3f)) { g.DrawCurve(p, Pts(5, -56, 8, -44, 5, -32), 0.5f); g.DrawCurve(p, Pts(-3, -20, -2, -6, -5, 8), 0.5f); }
        // empuñadura
        using (var b = new SolidBrush(RedDark)) g.FillRectangle(b, -5.5f, 38, 11, 16);
        using (var p = P(Ink, 1.5f)) g.DrawRectangle(p, -5.5f, 38, 11, 16);
    }

    // Dibuja un simbolo (0 oros, 1 copas, 2 espadas, 3 bastos) con centro y altura dados.
    static void Symbol(Graphics g, int suit, float cx, float cy, float height, float angle)
    {
        var st = g.Save();
        g.TranslateTransform(cx, cy);
        g.RotateTransform(angle);
        float s = height / 100f;
        g.ScaleTransform(s, s);
        // centra en el origen la caja real de cada dibujo (espada -100..33, basto -92..54)
        if (suit == 2) g.TranslateTransform(0, 33.5f);
        else if (suit == 3) g.TranslateTransform(0, 19f);
        if (suit == 0) Coin(g, 0, 0, 48);
        else if (suit == 1) Cup(g);
        else if (suit == 2) Sword(g);
        else Club(g);
        g.Restore(st);
    }

    // ---------- caballo con jinete ----------
    // Espacio local de ~100 x 112, mirando a la derecha; el suelo esta en y=110.
    static void HorseRider(Graphics g, int suit)
    {
        Color[] coat = { C("#C58A4A"), C("#8C4B2F"), C("#B3BAC6"), C("#5A4338") };
        Color[] mane = { C("#5E3B1C"), C("#2A1810"), C("#5C6370"), C("#1E1511") };
        Color[] tunic = { Gold, Red, Blue, Green };
        Color[] tunicDark = { GoldDark, RedDark, BlueDark, GreenDark };
        Color[] cloth = { Green, Gold, Red, Gold };
        Color c = coat[suit], m = mane[suit], far = Mix(coat[suit], Ink, 0.30f);
        Color hoof = C("#3B2A20");
        Color tu = tunic[suit], td = tunicDark[suit];

        // sombra en el suelo
        using (var b = new SolidBrush(Color.FromArgb(55, 40, 30, 20))) g.FillEllipse(b, 6, 106, 90, 9);

        // cola (detras)
        Limb(g, m, 7.5f, 1.3f, 0.5f, 16, 68, 5, 72, 2, 86, 7, 100);
        // patas lejanas
        Limb(g, far, 7f, 1.3f, 0.3f, 65, 78, 66, 94, 65, 107);
        Limb(g, far, 7f, 1.3f, 0.3f, 26, 76, 36, 93, 33, 107);
        // patas cercanas (delantera levantada)
        Limb(g, c, 7.5f, 1.3f, 0.3f, 71, 78, 82, 89, 73, 99);
        Limb(g, c, 7.5f, 1.3f, 0.3f, 19, 76, 12, 93, 15, 107);
        // cascos
        Ell(g, hoof, Ink, 1f, 65, 107.2f, 4.4f, 3.1f);
        Ell(g, hoof, Ink, 1f, 33, 107.2f, 4.4f, 3.1f);
        Ell(g, hoof, Ink, 1f, 15, 107.2f, 4.4f, 3.1f);
        Ell(g, hoof, Ink, 1f, 72.6f, 99.3f, 4.4f, 3.1f);

        // oreja
        Poly(g, c, Ink, 1.3f, Pts(77, 30, 79, 17, 85, 29));
        // cuerpo + cuello + cabeza
        PointF[] body = Pts(
            12, 70,  24, 62,  40, 64,  56, 60,  64, 50,  71, 38,  76, 29,  82, 25,
            88, 31,  95, 43,  98.5f, 50,  95.5f, 55,  89, 52,  83, 47,  78, 53,
            73, 65,  69, 77,  60, 85,  44, 87,  30, 85,  20, 81,  11, 75);
        Curve(g, c, Ink, 1.7f, body, 0.32f);
        // vientre: sombreado suave
        using (var p = P(Color.FromArgb(70, 40, 20, 10), 4f)) g.DrawCurve(p, Pts(26, 82, 44, 85, 60, 82, 68, 74), 0.4f);
        // crin
        Limb(g, m, 5.2f, 1.2f, 0.4f, 58, 58, 66, 47, 73, 36, 78, 27);
        // ojo, nariz, rienda
        Ell(g, Ink, Ink, 0, 87.5f, 34, 1.7f, 1.7f);
        Ell(g, Ink, Ink, 0, 96.5f, 48, 1.1f, 1.1f);
        using (var p = P(Mix(tu, Ink, 0.15f), 1.6f)) g.DrawLine(p, 84, 30, 91, 50);

        // manta de la silla
        Poly(g, cloth[suit], Ink, 1.5f, Pts(35, 62, 58, 60, 61, 75, 33, 76));
        using (var p = P(Mix(cloth[suit], Color.White, 0.5f), 1.4f)) g.DrawLine(p, 37, 71, 58, 71);

        // pierna del jinete
        Limb(g, td, 7f, 1.3f, 0.3f, 46, 62, 55, 75, 53, 88);
        using (var p = P(hoof, 8f)) g.DrawLine(p, 53, 87, 54.5f, 90.5f);
        // torso
        Limb(g, tu, 15f, 1.5f, 0.0f, 46, 62, 50, 36);
        using (var p = P(Color.FromArgb(110, 255, 255, 255), 2.6f)) g.DrawLine(p, 43, 44, 56, 58); // banda
        using (var p = P(td, 2.2f)) g.DrawLine(p, 41, 58, 55, 62);                                 // cinturon
        // brazo y mano (levantada, sujeta el objeto del palo)
        Limb(g, tu, 6f, 1.3f, 0.3f, 53, 39, 61, 41, 66, 34);
        Ell(g, Skin, Ink, 1.2f, 67, 32.5f, 3.4f, 3.4f);
        // cabeza y sombrero
        Ell(g, Skin, Ink, 1.5f, 51, 24, 6.6f, 6.9f);
        Ell(g, Ink, Ink, 0, 54, 24, 0.9f, 0.9f);
        Ell(g, tu, Ink, 1.5f, 51, 18.5f, 10, 4.6f);
        Ell(g, tu, Ink, 1.5f, 52, 14.5f, 6.2f, 5f);
        using (var p = P(Mix(Color.White, tu, 0.1f), 2.6f)) g.DrawCurve(p, Pts(56, 12, 64, 6, 69, 11), 0.5f);

        // objeto en la mano (delante de la mano)
        var st = g.Save();
        // el origen de cada objeto se coloca para que su empuñadura quede en la mano (67,32.5)
        if (suit == 0) { g.TranslateTransform(67, 32.5f - 10); g.ScaleTransform(0.18f, 0.18f); Coin(g, 0, 0, 48); }
        else if (suit == 1) { g.TranslateTransform(67, 32.5f - 18 * 0.28f); g.ScaleTransform(0.28f, 0.28f); Cup(g); }
        else if (suit == 2) { g.TranslateTransform(67, 32.5f - 8 * 0.30f); g.RotateTransform(6); g.ScaleTransform(0.30f, 0.30f); Sword(g); }
        else { g.TranslateTransform(67, 32.5f - 46 * 0.22f); g.RotateTransform(12); g.ScaleTransform(0.22f, 0.22f); Club(g); }
        g.Restore(st);
        // la mano tapa el pie del objeto
        Ell(g, Skin, Ink, 1.2f, 67, 32.5f, 3.4f, 3.4f);
    }

    static void CaballoCard(Graphics g, int suit)
    {
        // simbolo del palo en la esquina, como en las cartas originales
        Symbol(g, suit, 230, 70, suit == 0 ? 56 : (suit == 1 ? 62 : (suit == 2 ? 58 : 66)), suit == 2 ? 24 : (suit == 3 ? 24 : 0));
        var st = g.Save();
        float s = 2.45f;
        g.TranslateTransform(150 - 50 * s, 246 - 56 * s);
        g.ScaleTransform(s, s);
        HorseRider(g, suit);
        g.Restore(st);
    }

    // ---------- distribucion de monedas (centro y diametro medidos de la baraja original) ----------
    static readonly float[][] Pips = new float[][]
    {
        null,
        null,
        new float[] { 149,121,134, 149,337,134 },
        new float[] { 99,99,120, 199,229,120, 99,359,120 },
        new float[] { 81,81,85, 218,81,85, 81,378,85, 218,378,85 },
        new float[] { 81,81,85, 218,81,85, 149,229,134, 81,378,85, 218,378,85 },
        new float[] { 81,81,85, 218,81,85, 81,229,85, 218,229,85, 81,378,85, 218,378,85 },
        new float[] { 81,81,85, 218,81,85, 149,154,86, 81,229,85, 218,229,85, 81,378,85, 218,378,85 },
        new float[] { 81,81,85, 218,81,85, 149,154,86, 81,229,85, 218,229,85, 149,304,86, 81,378,85, 218,378,85 },
        new float[] { 78,78,80, 220,78,80, 149,128,80, 78,179,80, 220,179,80, 78,280,80, 220,280,80, 78,380,80, 220,380,80 }
    };

    public static void Run(string cardsDir, string[] outDirs, string sheetPath)
    {
        int[] bg = BuildBg(cardsDir);
        var made = new Dictionary<string, Bitmap>();

        // As de oros: base limpia desde el as de copas (mismo marco y numero "1").
        using (var b = Load(Path.Combine(cardsDir, "copas_1.png")))
        {
            ClearInterior(b, bg, false, null);
            using (var g = Gfx(b)) AsDeOros(g);
            made["oros_1"] = (Bitmap)b.Clone();
        }
        // oros 2..9
        for (int n = 2; n <= 9; n++)
        {
            using (var b = Load(Path.Combine(cardsDir, "oros_" + n + ".png")))
            {
                ClearInterior(b, bg, false, Pips[n]);
                using (var g = Gfx(b))
                {
                    float[] pp = Pips[n];
                    for (int k = 0; k < pp.Length; k += 3) Coin(g, pp[k], pp[k + 1], pp[k + 2] / 2f + 1f);
                }
                made["oros_" + n] = (Bitmap)b.Clone();
            }
        }
        // oros 10 y 12: solo la moneda de la esquina
        float[][] corner = new float[][] { new float[] { 10, 89, 76, 67 }, new float[] { 12, 232, 67, 66 } };
        foreach (float[] c in corner)
        {
            using (var b = Load(Path.Combine(cardsDir, "oros_" + (int)c[0] + ".png")))
            {
                float r = c[3] / 2f;
                ClearDisc(b, bg, c[1], c[2], r + 5f);
                using (var g = Gfx(b)) Coin(g, c[1], c[2], r + 2f);
                made["oros_" + (int)c[0]] = (Bitmap)b.Clone();
            }
        }
        // caballos (11)
        string[] names = { "oros", "copas", "espadas", "bastos" };
        for (int s = 0; s < 4; s++)
        {
            using (var b = Load(Path.Combine(cardsDir, names[s] + "_11.png")))
            {
                ClearInterior(b, bg, true, null);
                using (var g = Gfx(b)) CaballoCard(g, s);
                made[names[s] + "_11"] = (Bitmap)b.Clone();
            }
        }

        foreach (string d in outDirs)
        {
            Directory.CreateDirectory(d);
            foreach (var kv in made) kv.Value.Save(Path.Combine(d, kv.Key + ".png"), ImageFormat.Png);
        }

        if (!string.IsNullOrEmpty(sheetPath))
        {
            string[] order = { "oros_1","oros_2","oros_3","oros_4","oros_5","oros_6","oros_7","oros_8","oros_9","oros_10","oros_11","oros_12",
                               "copas_11","espadas_11","bastos_11" };
            int cols = 5, rows = 3;
            using (var sheet = new Bitmap(cols * W, rows * H))
            using (var g = Graphics.FromImage(sheet))
            {
                g.Clear(Color.FromArgb(120, 120, 120));
                for (int i = 0; i < order.Length; i++)
                {
                    Bitmap src = made.ContainsKey(order[i]) ? made[order[i]] : null;
                    if (src == null) continue;
                    g.DrawImage(src, (i % cols) * W, (i / cols) * H, W, H);
                }
                sheet.Save(sheetPath, ImageFormat.Png);
            }
        }
        foreach (var kv in made) kv.Value.Dispose();
    }
}
'@

$cards = Join-Path $Repo 'assets\cards'
if ($Salida -ne '') {
    [CartasPropias]::Run($cards, @($Salida), (Join-Path $Salida 'hoja.png'))
    Write-Host "Cartas de prueba en $Salida (hoja.png). No se ha tocado el repo."
} else {
    $docs = Join-Path $Repo 'docs\cartas'
    [CartasPropias]::Run($cards, @($cards, $docs), '')
    Write-Host "Cartas propias escritas en assets\cards y docs\cartas."
}
