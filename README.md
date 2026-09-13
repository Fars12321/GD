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

الأصول النموذجية/الصوتية **غير مُلتزمة في Git** بصورتها النهائية؛ تُعاد بناؤها من ملفات ZIP داخل المستودع.

**أي نظام (يحتاج Python 3 فقط — يعمل على ويندوز دون bash):**
```bash
python ci/bootstrap_assets.py
```

**أو على لينكس/ماك (bash + unzip):**
```bash
bash ci/bootstrap_assets.sh
```

بعدها افتح `project.godot` في Godot 4.3 وشغّل `scenes/Main.tscn`.
بدون هذه الخطوة سيفشل تحميل `scenes/buildings/Wall.tscn` و`Tower.tscn` (تعتمد على `assets/models/castle-kit/*.glb`).

## الفحص

**الطريقة الأسهل (كل الأنظمة):**
```bash
python ci/check_all.py
```

**مع تحديد مكان المحرّك يدويًا:**
```bash
# لينكس / ماك
GODOT_BIN=/path/to/godot python ci/check_all.py

# ويندوز (PowerShell)
$env:GODOT_BIN="C:\godot\Godot_v4.3-stable_win64.exe"; python ci/check_all.py
```

**أو عبر bash:** `bash ci/check_all.sh`

كلها تنفّذ: إعادة بناء الأصول ← الفحص الثابت ← اختبارات Godot بلا رأس (تُتخطّى إن لم يوجد المحرّك).

| الفحص | ماذا يغطّي | يحتاج Godot؟ |
|-------|-----------|--------------|
| `python ci/static_check.py` | سلامة `.tscn` (عدد `load_steps`، مراجع `ExtResource`/`SubResource`، وجود الملفات)، **مسارات كل `$Path` و`get_node()` مقابل شجرة المشهد الحقيقية**، مسارات `res://`، خلط الجدولة/المسافات، توازن الأقواس، المجموعات (`add_to_group` ↔ `get_first_node_in_group`) | ❌ لا |
| `ci/godot_smoke.gd` | تحميل كل السكربتات + توليد `Main.tscn` والتحقق من العُقد الأساسية | ✅ نعم |
| `ci/godot_smoke_roguelite.gd` | الدورة ليل/نهار، تولّد الموجات، مكافأة القتل، سحب 3 بطاقات فريدة، الإيقاف المؤقت أثناء الاختيار، تطبيق الترقية، تقدّم اليوم، صحة القلعة، وحالة الهزيمة | ✅ نعم |

**تنزيل Godot 4.3:** من <https://godotengine.org/download/archive/4.3-stable/> — النسخة العادية (ليست `.NET`). الملف التنفيذي واحد لا يحتاج تثبيتًا؛ ضعه في مجلد ومرّر مساره عبر `GODOT_BIN`.

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

**كل التشغيلات متوقفة بسبب فوترة الحساب، لا بسبب الكود.** آخر دليل (تشغيل `34770908713` على هذا الفرع):
> *"The job was not started because recent account payments have failed or your spending limit needs to be increased. Please check the 'Billing & plans' section in your settings"*

الوظيفتان فشلتا في 3 ثوانٍ دون أن تبدآ — حتى وظيفة `static` التي لا تحتاج Godot، لأن المستودع **خاص** وأي مُشغِّل مستضاف على GitHub يستهلك دقائق مدفوعة.
إلى أن يُصلَح ذلك من <https://github.com/settings/billing>، استخدم `python ci/check_all.py` محليًا.
