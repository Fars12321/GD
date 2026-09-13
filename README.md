# Village Defense — «ليلة واحدة»

لعبة دفاع **roguelite** للهاتف مبنية بمحرّك **Godot 4.3** (المُصيِّر `gl_compatibility` ليعمل على أوسع مدى من الأجهزة).

## حلقة اللعب

| الطور | المدة | ماذا تفعل |
|-------|-------|-----------|
| **نهار** | 40 ثانية | اجمع الخشب والحجر من الأشجار والصخور، وابنِ الأسوار والأبراج على شبكة 2م |
| **ليل** | 60 ثانية (أو حتى سقوط كل الأعداء) | هياكل عظمية تهاجم قلعتك؛ أبراجك تطلق تلقائيًا، وأنت تهاجم بزر **⚔ هجوم** |
| **البطاقات** | — | بعد كل ليلة تصمد فيها: **اختر ترقية واحدة من 3** |

سقوط القلعة أو سقوط الملك = نهاية الجولة، ثم تبدأ من جديد بترقيات مختلفة. لا جولتان متشابهتان.

## التشغيل (خطوة إلزامية قبل فتح المشروع)

الأصول النموذجية/الصوتية **غير مُلتزمة في Git** بصورتها النهائية؛ تُعاد بناؤها من ملفات ZIP داخل المستودع:

```bash
bash ci/bootstrap_assets.sh     # يبني مجلد assets/ من ملفات ZIP
```

بعدها افتح `project.godot` في Godot 4.3 وشغّل `scenes/Main.tscn`.
بدون هذه الخطوة سيفشل تحميل `scenes/buildings/Wall.tscn` و`Tower.tscn` (تعتمد على `assets/models/castle-kit/*.glb`).

## الفحص

```bash
bash ci/check_all.sh
```

ينفّذ: إعادة بناء الأصول ← الفحص الثابت ← اختبارات Godot بلا رأس (إن كان `godot` في PATH، وإلا يتخطّاها).

| الفحص | ماذا يغطّي | يحتاج Godot؟ |
|-------|-----------|--------------|
| `python3 ci/static_check.py` | سلامة `.tscn` (عدد `load_steps`، مراجع `ExtResource`/`SubResource`، وجود الملفات)، **مسارات كل `$Path` و`get_node()` مقابل شجرة المشهد الحقيقية**، مسارات `res://`، خلط الجدولة/المسافات، توازن الأقواس، المجموعات (`add_to_group` ↔ `get_first_node_in_group`) | ❌ لا |
| `ci/godot_smoke.gd` | تحميل كل السكربتات + توليد `Main.tscn` والتحقق من العُقد الأساسية | ✅ نعم |
| `ci/godot_smoke_roguelite.gd` | الدورة ليل/نهار، تولّد الموجات، مكافأة القتل، سحب 3 بطاقات فريدة، الإيقاف المؤقت أثناء الاختيار، تطبيق الترقية، تقدّم اليوم، صحة القلعة، وحالة الهزيمة | ✅ نعم |

## التحكم

- **العصا الافتراضية** (أسفل اليسار) أو أسهم لوحة المفاتيح: حركة الملك.
- **جمع**: يظهر الزر عند الاقتراب من شجرة أو صخرة.
- **بناء**: زر «بناء» ← سور (🪵2 🪨1) أو برج (🪵3 🪨6) ← حرّك المعاينة ← ✓ تأكيد / ✗ إلغاء.
- **⚔ هجوم**: يظهر في الليل فقط، يضرب أقرب عدو داخل 2.4م.

## البنية

```
scenes/Main.tscn            ← العالم: أرض، قلعة، إضاءة، NavigationRegion3D، وكل المديرين
scripts/
  roguelite_director.gd     ← حالة الجولة (DAY/NIGHT/CARDS/OVER) + تطبيق البطاقات
  day_night_manager.gd      ← الدورة والإضاءة؛ night_cleared عند تصفية الموجة
  wave_spawner.gd           ← موجات متصاعدة + مكافأة موارد لكل هيكل يسقط
  enemy.gd                  ← هيكل عظمي: NavigationAgent3D، يستهدف أقرب مبنى/الملك
  castle_core.gd            ← صحة القلعة وشرط الهزيمة
  upgrade_deck.gd           ← 12 بطاقة ترقية (بيانات)
  run_stats.gd              ← مضاعفات الجولة التي تقرأها الأبراج والملك والأعداء
  buildings/tower.gd        ← برج يطلق مقذوفات (projectile.gd)
  buildings/wall.gd         ← سور قابل للتدمير
  player.gd / camera_rig.gd / resource_node.gd / building_manager.gd / ui.gd / virtual_joystick.gd
scenes/ui/UpgradeOverlay.tscn  ← شاشة «اختر بطاقة من 3» + شاشة نهاية الجولة
```

**إضافة بطاقة جديدة:** أضف سجلًا في `UpgradeDeck.CARDS` ثم فرعًا في `roguelite_director.gd::_apply_card()`. لا شيء آخر.

## الأصول

- **Kenney** — castle-kit / hexagon-kit / fantasy-town-kit / mini-forest / cartography-pack / impact-sounds / ui-audio (رخصة كل حزمة داخل ملفها `License.txt`).
- **KayKit** — Forest Nature Pack، Character Pack Skeletons (أُعيد بناؤه إلى `assets/characters/` مع `KayKit-Skeletons-LICENSE.txt`).

## حالة CI

`.github/workflows/godot-smoke.yml` يشغّل وظيفتين: `static` (بلا Godot) و`godot` (smoke + roguelite smoke + لقطة شاشة + حزمة).
**ملاحظة:** تشغيلات GitHub Actions متوقفة حاليًا بسبب حدّ الإنفاق في الحساب — رسالة GitHub على التشغيلات هي *"The job was not started because recent account payments have failed…"*. إلى أن يُصلَح ذلك، استخدم `bash ci/check_all.sh` محليًا.
