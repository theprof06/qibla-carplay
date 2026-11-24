# القبلة على CarPlay

تطبيق آيفون فيه بوصلة قبلة، ومعاه **أداة (Widget)** بتظهر على شاشة العربية في CarPlay (iOS 26 وأحدث).

- **على الموبايل:** بوصلة بتلف مع الموبايل، وبتقولك "لف يمين/شمال" لحد ما تتوجه للقبلة. ولو العربية ماشية، بيقولك القبلة على يمينك ولا شمالك حسب اتجاه السير.
- **على CarPlay:** زاوية القبلة من مكانك (مثلاً 253° غرب جنوب غرب) وسهم ثابت والشمال لفوق، علشان تقارنها باتجاه العربية في التابلوه.

البناء كله بيتعمل على سيرفرات Mac تبع GitHub، فمش محتاج جهاز Mac.

---

## الخطوات (كلها من المتصفح)

### ١. حساب مطور Apple (99 دولار في السنة)
- الأسهل من الآيفون: نزّل تطبيق **Apple Developer** ← Account ← **Enroll Now**، وادفع من جوه التطبيق.
- أو من المتصفح: https://developer.apple.com/programs/enroll/
- الموافقة بتاخد من ساعات لحد يومين.

### ٢. سجّل الـ Bundle ID
https://developer.apple.com/account/resources/identifiers/list ← علامة **+** ← **App IDs** ← **App**
- Description: `Qibla Car`
- Bundle ID: اختار **Explicit** واكتب `com.theprof06.qiblacar`
- Continue ← Register (مش محتاج تختار أي Capabilities)

### ٣. اعمل التطبيق في App Store Connect
https://appstoreconnect.apple.com/apps ← **+** ← **New App**
- Platform: iOS
- Name: أي اسم مش مستخدم، مثلاً `Qibla Car Mohamed` (الاسم ده للمتجر بس، أما على الموبايل فهيظهر "القبلة")
- Primary language: Arabic
- Bundle ID: اختار `com.theprof06.qiblacar`
- SKU: `qiblacar`
- User Access: Full Access

### ٤. اعمل مفتاح API
https://appstoreconnect.apple.com/access/integrations/api ← **Team Keys** ← **+**
- Name: `GitHub`
- Access: **Admin** (لازم Admin علشان يقدر يعمل شهادات التوقيع)
- اضغط **Download** ونزّل ملف `.p8`. **الملف ده بيتنزل مرة واحدة بس**، فاحفظه كويس.
- انسخ **Key ID** (جنب المفتاح) و**Issuer ID** (فوق الجدول).

### ٥. هات الـ Team ID
https://developer.apple.com/account ← **Membership details** ← **Team ID** (10 حروف وأرقام)

### ٦. حط الأسرار في GitHub
في الريبو: **Settings ← Secrets and variables ← Actions ← New repository secret**، واعمل 4 أسرار:

| الاسم | القيمة |
|---|---|
| `ASC_KEY_ID` | الـ Key ID من خطوة ٤ |
| `ASC_ISSUER_ID` | الـ Issuer ID من خطوة ٤ |
| `TEAM_ID` | الـ Team ID من خطوة ٥ |
| `ASC_KEY_P8` | افتح ملف `.p8` بـ Notepad وانسخ كل اللي فيه، بما فيه سطر `-----BEGIN PRIVATE KEY-----` وسطر `-----END PRIVATE KEY-----` |

### ٧. ابني وارفع
تبويب **Actions** ← **TestFlight** ← **Run workflow** ← Run.
بياخد حوالي 10 دقايق. لو ظهرت علامة ✅ خضرا يبقى اترفع.

### ٨. نزّله على موبايلك
- App Store Connect ← التطبيق ← **TestFlight**. استنى لحد ما الـ Build يخلص Processing (5–15 دقيقة).
- لو طلب **Export Compliance** اختار None.
- **Internal Testing** ← **+** ← اعمل جروب وضيف نفسك.
- نزّل تطبيق **TestFlight** من App Store، وهتلاقي "القبلة" جاهز للتثبيت.

> نسخ TestFlight صلاحيتها 90 يوم. قبل ما تخلص، شغّل الـ workflow تاني (خطوة ٧) وهتنزلك نسخة جديدة.

### ٩. فعّله على CarPlay
- افتح التطبيق مرة واحدة واسمح بالموقع (**While Using the App**).
- **الإعدادات ← عام ← CarPlay ← عربيتك ← Widgets** وضيف **«اتجاه القبلة»**.
- على شاشة العربية اسحب لحد صفحة الـ Widgets.

---

## إزاي تقرأه في العربية
الرقم هو زاوية القبلة من الشمال. قارنه باتجاه العربية اللي في التابلوه أو الخريطة:
- اتجاه العربية = زاوية القبلة ← القبلة قدامك.
- مثال من الدوحة: القبلة حوالي **253°**. لو العربية رايحة غرب (270°)، يبقى القبلة مايلة شوية لشمالك.

## محتويات المشروع
| الملف | الوظيفة |
|---|---|
| `Shared/Qibla.swift` | حساب الزاوية والمسافة وأسماء الاتجاهات |
| `Shared/CompassDial.swift` | رسمة البوصلة والسهم |
| `App/` | تطبيق الموبايل (بوصلة حيّة + وضع العربية) |
| `Widget/` | الأداة اللي بتظهر على CarPlay والـ Lock Screen |
| `project.yml` | تعريف المشروع (XcodeGen بيحوّله لمشروع Xcode) |
| `.github/workflows/` | البناء والرفع على سيرفرات GitHub |
