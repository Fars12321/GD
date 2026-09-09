# GD Kingdom — لعبة استراتيجية وبناء قرية 3D للهواتف

مشروع لعبة ثلاثية الأبعاد (استراتيجية + بناء قرية) مبنية بمحرك **Godot 4** وبلسان
**GDScript**، مستهدفة الهواتف الذكية بمحرك العرض **GL Compatibility (OpenGL ES 3.0)**.

---

## ⬇️ تحميل اللعبة

| الملف | الحجم | الرابط |
|---|---|---|
| **Phase 2** — جمع الموارد + الواجهة (كود + أصول مستخدمة) | ~291 KB | `builds/GD_Phase2_game_only.zip` |
| **Phase 1** — تحكم الملك والكاميرا (نسخة سابقة) | ~171 KB | `builds/GD_Phase1_game_only.zip` |
| تحميل مباشر (GitHub — يتطلب الدخول لأن المستودع خاص) | — | https://github.com/Fars12321/GD/raw/arena/01a083a9-gd/builds/GD_Phase2_game_only.zip |

> **ملاحظة:** المستودع **خاص (Private)** حاليًا، لذا تتطلب روابط GitHub تسجيل الدخول بحساب
> يملك صلاحية الوصول. للتحميل الفوري دون GitHub، استخدم بطاقة المعاينة الحية
> (Live Preview) الخاصة بجلسة التطوير في Arena.

**طريقة التشغيل بعد فك الضغط:**
1. ثبّت **Godot 4.3 أو أحدث** (مجانًا من godotengine.org) إن لم يكن مثبتًا.
2. افتح ملف `project.godot` داخل المجلد بمحرر Godot.
3. اضغط **F5** لتشغيل اللعبة.
4. التحكم: **WASD / الأسهم** أو **السحب بالفأرة** على الحاسوب — وعلى الهاتف اسحب بإصبعك فتظهر عصا التحكم. اقترب من شجرة/صخرة وسيظهر زر **Collect** تلقائيًا.

---

## 📁 هيكل المشروع

```
├── project.godot          # إعدادات المحرك (Godot 4.3+ / GL Compatibility)
├── assets/                # الأصول المستخرجة (KayKit + Kenney) — تُستدعى دائماً عبر res://assets/
│   ├── kaykit_adventurers_2/        # شخصيات المغامرين (Knight = الملك) + حركات Rig_Medium
│   ├── kaykit_character_animations/ # مكتبة حركات الشخصيات (Rig_Medium / Rig_Large)
│   ├── kaykit_forest_nature/        # طبيعة وغابة
│   ├── kaykit_skeletons_1/          # شخصيات الهياكل العظمية (أعداء مستقبلياً)
│   ├── kaykit_character_pack_*/     # إضافات Godot للحزم (مرجعية)
│   ├── kenney_castle_kit/           # قلعة ومباني
│   ├── kenney_fantasy_town/         # بلدة خيالية
│   ├── kenney_hexagon/              # مكعبات سداسية (خريطة استراتيجية)
│   ├── kenney_mini_forest/          # غابة مصغّرة
│   ├── kenney_cartography/          # رموز خرائط (واجهات)
│   ├── kenney_impact_sounds/        # مؤثرات (خطوات، اصطدامات)
│   └── kenney_ui_audio/             # أصوات واجهة
├── scenes/                # مشاهد Godot (.tscn)
├── scripts/               # سكربتات GDScript
└── tools/                 # أدوات تطوير (استخراج الأصول)
```

> ملفات ZIP الأصلية للأصول محفوظة على فرع `main`. أداة إعادة الاستخراج:
> `python3 tools/extract_assets.py` (تُشغَّل وملفات ZIP في جذر المستودع).

---

## ✅ Phase 2 — نظام جمع الموارد والواجهة (منجز)

| الملف | الوظيفة |
|---|---|
| `scenes/resource_node.tscn` + `scripts/resource_node.gd` | عقدة مورد (`Area3D` + `CollisionShape3D` كرة تفاعل) بنوعَين `WOOD/STONE`. الجمع `gather()` يخصم كمية، يشغّل صوت Kenney (`impactMining` للحجر / `impactWood` للخشب)، يهزّ المجسّم بـ Tween، وعند النفاد ينكمش ويُحذف `queue_free()`. يبث `resource_collected(type, amount)` |
| `scenes/main.tscn` | 5 أشجار (`Tree_1_A` / `Tree_3_A`) + 5 صخور (`Rock_1_A` / `Rock_3_A`) من `res://assets/kaykit_forest_nature/` موزّعة حول القرية التجريبية |
| `scripts/player.gd` | عدّادا `wood_count`/`stone_count`، فحص الموارد داخل مدى التفاعل وترتيبها، `get_nearest_resource()` / `gather_nearest()`، بث `resources_changed(wood, stone)` و`nearest_resource_changed(resource)` |
| `scripts/ui.gd` + `scenes/ui.tscn` | شريط علوي بعدّادي الخشب والحجر + زر **Collect** كبير يظهر/يختفي تلقائيًا عند الاقتراب/الابتعاد عن مورد، مع تحديث الكمية المتبقية عليه |
| `scripts/virtual_joystick.gd` | تحسين: لا تبدأ العصا فوق أزرار الواجهة (`ui_blockers`) — يدعم الضغط المتزامن: حركة بإصبع + جمع بإصبع آخر |

**أصول مستخدمة فعليًا:** مجسّمات KayKit Forest (`Tree_1_A`, `Tree_3_A`, `Rock_1_A`, `Rock_3_A`)
وأصوات Kenney Impact (`impactWood_medium_000`, `impactMining_000`) — كلها تحت `res://assets/`.

---

## ✅ Phase 1 — نظام تحكم الملك والكاميرا (منجز)

| الملف | الوظيفة |
|---|---|
| `scenes/main.tscn` + `scripts/main.gd` | المشهد الرئيسي: يجمع مدخلات العصا والأسهم، يحوّلها عبر الكاميرا لاتجاه عالمي، يمررها للملك. يجهّز أرضية اختبار 160×160 + إضاءة شمس + علامات بصرية |
| `scenes/player.tscn` + `scripts/player.gd` | الملك (`CharacterBody3D`) بمجسّم **Knight.glb** (KayKit) — حركة سلسة بتسارع/تباطؤ أُسّي، ودوران تلقائي ناعم نحو اتجاه الحركة |
| `scenes/ui.tscn` + `scripts/virtual_joystick.gd` | عصا تحكم لمسية مرسومة برمجياً (`_draw`) تدعم `InputEventScreenTouch/Drag` واللمس المتعدد، مع وضع Dynamic (تظهر مكان اللمسة) |
| `scripts/camera_rig.gd` | ذراع كاميرا بمنظور علوي مائل (ثلاثة أرباع) تتبع الملك بسلاسة عبر Lerp أُسّي، وتُستخدم لتحويل مدخلات الشاشة إلى اتجاه حركة |
| `scripts/input_setup.gd` | Autoload يُسجّل أزرار الحركة (WASD + الأسهم) وعصا التحكم الفيزيائية |

### ▶️ التشغيل والاختبار

1. افتح المشروع بـ **Godot 4.3 أو أحدث** (`project.godot`).
2. شغّل المشهد الرئيسي `scenes/main.tscn` (F5).
3. التحكم:
   - **هاتف**: اسحب بإصبعك في أي مكان — تظهر عصا تحكم ديناميكية مكان اللمسة.
   - **حاسوب**: WASD أو أسهم لوحة المفاتيح، أو اسحب بالفأرة (محاكاة لمس مفعّلة).
4. اضبط إن لزم: ارتفاع/مسافة الكاميرا من عقدة `CameraRig`، وسرعة الملك من عقدة `King`.

> ملاحظة أداء: دقة العرض 3D مضبوطة على 75% مبدئياً لراحة الهواتف، وقابلة
> للتعديل من `project.godot` ← `rendering/scaling_3d/scale`.

> ملاحظة تواجه: شخصيات KayKit (glTF) تتجه نحو **+Z**. إذا بدا الملك يمشي
> للخلف على جهازك اضبط `facing_yaw_offset_deg = 180` على عقدة `King`.

---

## 🗺️ خارطة الطريق المقترحة (تُنفَّذ مرحلة-بمرحلة)

1. ✅ التحكم بالملك والكاميرا (Phase 1).
2. ✅ جمع الموارد (خشب/حجر) والواجهة (Phase 2).
3. حركات المشي/التوقف من مكتبة `kaykit_character_animations` (Rig_Medium).
3. بناء القرية: تنسيق أرضي، وضع مباني من حزم Kenney بنظام شبكة/تصادم.
4. نظام تحديد وبناء المباني عبر اللمس + واجهة موارد.
5. ذكاء اصطناعي: فلاحون/عمال، إدارة موارد، أعداء (KayKit Skeletons).
   … وهكذا حسب تأكيد كل مرحلة قبل بدء التالية.

---

## 📜 الترخيص

الأصول المجمّعة من حزم مجانية:
- **KayKit** — رخصة KayKit (استخدام مجاني، يُذكر المصدر).
- **Kenney** — رخصة CC0 (ملكية عامة).
ملفات الترخيص الأصلية موجودة داخل مجلدات `assets/` لكل حزمة.
