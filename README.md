# Android Firebase Cloud Messaging

ตั้งค่าเมื่อ 18 พฤศจิกายน 2026 สำหรับ Android package `com.example.flutter_application_1`

## การตั้งค่าที่ตรวจสอบใน Chrome

- Firebase project: `burin-test` (Burin-test)
- Android app nickname: `test-app`
- App ID: `1:1019089048491:android:d9bffdeb8201cce61238ee`
- Sender ID: `1019089048491`
- Firebase Cloud Messaging API (V1): **Enabled อยู่แล้ว**
- Legacy API: Disabled; ไม่ต้องเปิดสำหรับการตั้งค่านี้
- ดาวน์โหลด `google-services.json` ล่าสุดจาก Console แทนไฟล์เดิมที่ App ID ไม่ตรง
- ไม่ได้สร้าง service-account private key หรือ Web Push certificate; Android client ไม่ต้องใช้ไฟล์เหล่านี้

## สิ่งที่เพิ่มในโปรเจกต์

- `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
- Google Services Gradle plugin, desugaring, สิทธิ์ INTERNET / POST_NOTIFICATIONS
- notification channel `high_importance_channel` และไอคอนแจ้งเตือนสีขาว
- เริ่ม Firebase จาก native Android configuration ใน `android/app/google-services.json`
- ปุ่มขอสิทธิ์แจ้งเตือน, แสดง/คัดลอก FCM registration token และรองรับ token refresh
- รับข้อความตอนเปิดแอปพร้อมแสดง system notification สำหรับ notification payload
- background handler และการเปิดแอปจาก notification ทั้ง background/terminated
- แสดงข้อความที่ได้รับขณะเปิดแอปหรือกดเปิดจากแจ้งเตือน สูงสุด 30 รายการในหน่วยความจำ

## รันและทดสอบบนมือถือ

1. เชื่อมต่อมือถือ Android ที่มี Google Play services และเปิด USB debugging หรือใช้ emulator แบบ Google Play/Google APIs
2. รัน `flutter pub get` แล้ว `flutter run`
3. กด **อนุญาตการแจ้งเตือน** ในแอป และยอมรับสิทธิ์บน Android 13 ขึ้นไป
4. กด **คัดลอก token**
5. เปิด [Firebase Console](https://console.firebase.google.com/u/1/project/burin-test/overview) > Messaging > Create your first campaign / New campaign > Firebase Notification messages
6. ใส่ title/body แล้วเลือก **Send test message** วาง FCM registration token และส่งเฉพาะอุปกรณ์ทดสอบ
7. ทดสอบตอนเปิดแอป (มีข้อความในหน้าแอปและ notification), กด Home (มี notification), และปิดแอปแล้วกด notification (เปิดแอปพร้อมข้อความ)

ถ้าปฏิเสธสิทธิ์ไปแล้ว ให้เปิด Notifications ใน Android Settings ของแอป แล้วกลับมากดรีเฟรช หาก force-stop จาก Settings ต้องเปิดแอปใหม่ก่อนรับข้อความได้อีก

ข้อความที่มี `notification` แสดงโดย Android อัตโนมัติเมื่อแอปอยู่เบื้องหลัง ส่วน data-only จะไม่สร้าง banner และการส่งขณะอยู่เบื้องหลังขึ้นกับ priority/ข้อจำกัดของ Android โดย handler ปัจจุบันบันทึกเฉพาะ message ID ใน log ไม่มีการจัดเก็บประวัติข้ามการเปิดแอป

FCM SDK รุ่นนี้มี `register()`/`onRegistered` ที่ใช้ FID แต่หน้านี้ยังใช้ API registration token ที่รองรับอยู่ เพื่อใช้กับช่องทดสอบใน Console และ backend HTTP v1 เดิม หากเพิ่ม backend ควรส่ง token ผ่าน API ที่ยืนยันตัวตนและอัปเดตเมื่อ token เปลี่ยน ห้ามใส่ service-account private key ลงในแอป

## ขอบเขตและผลตรวจสอบ

การตั้งค่านี้เป็น **Android เท่านั้น** ตามแอปในลิงก์ที่ให้มา iOS ยังไม่ได้ลงทะเบียน Firebase app / APNs key / Xcode Push Notifications capabilities และต้องตั้งค่าเพิ่มบน Mac

ผลตรวจสอบ:

- `flutter analyze`: ผ่าน ไม่พบปัญหา
- `flutter build apk --debug`: ผ่าน ได้ไฟล์ `build/app/outputs/flutter-apk/app-debug.apk`
- ตรวจ Google Services resources ที่ Gradle สร้างแล้ว ตรงกับ project/App ID/Sender ID ข้างต้น
- ติดตั้ง Android SDK Platform 34 เพิ่มโดย Gradle ตามที่ Firebase plugins ต้องใช้
- ขณะตั้งค่ายังไม่มีมือถือหรือ emulator เชื่อมต่อ (`adb devices` ว่าง) จึงยังยืนยันการรับ push จริงไม่ได้

## Build APK สำหรับ Firebase App Distribution

### คำสั่งสั้นใน terminal

ตั้งค่าครั้งเดียวใน PowerShell เพื่อติดตั้งคำสั่งในโฟลเดอร์ npm global เดียวกับ Firebase CLI:

```powershell
& C:\inf\flutter\helllo2\flutter_application_1\scripts\setup-terminal.ps1
```

จากนั้นพิมพ์คำสั่งได้จากทุกโฟลเดอร์ โดยไม่ต้องใส่ `.\` หรือชื่อไฟล์ `.ps1`:

```powershell
build-appdistribution
build-appdistribution -Upload -ReleaseNotes 'Test build'
```

บนเครื่องนี้ตัวเรียกอยู่ที่ `C:\Users\Burins\AppData\Roaming\npm\build-appdistribution.cmd`
ซึ่งอยู่บน PATH เดิมของ terminal ที่ใช้ Firebase CLI อยู่แล้ว จึงไม่ต้องโหลด PATH ใหม่ทุกครั้ง
สคริปต์ setup รันซ้ำได้ และอัปเดตตัวเรียกให้ชี้มาที่โปรเจกต์ปัจจุบัน
คำสั่งสั้นเรียกสคริปต์ PowerShell เดิมและส่งต่อ parameters
โดยใช้ execution policy เฉพาะ process ที่เรียก ไม่เปลี่ยน execution policy ของเครื่อง

หากต้องการเรียกโดยตรงจากโฟลเดอร์โปรเจกต์โดยไม่ใช้ PATH:

```powershell
.\scripts\bin\build-appdistribution.cmd -Upload -ReleaseNotes 'Test build'
```

### เรียกสคริปต์โดยตรง

รันจากโฟลเดอร์ `C:\inf\flutter\helllo2\flutter_application_1` ด้วย PowerShell:

```powershell
.\scripts\build-appdistribution.ps1
```

สคริปต์โหลด Flutter/Android/Java จาก `C:\inf\flutter\activate.ps1` ให้อัตโนมัติเมื่อมีไฟล์นี้
แล้วรัน `flutter pub get` และ `flutter build apk --release` ได้ APK รวมทุก ABI ที่
`build/app/outputs/flutter-apk/app-release.apk` สำหรับอัปโหลดใน
[Firebase App Distribution](https://console.firebase.google.com/u/1/project/burin-test/appdistribution/app/android:com.example.flutter_application_1/releases?hl=th)

สคริปต์ใช้ `version` จาก `pubspec.yaml` โดยตรงผ่าน Flutter ไม่ต้องระบุ `-BuildNumber`
หรือ `-BuildName` ในคำสั่งอีก ให้แก้เวอร์ชันในไฟล์ก่อนส่ง release ใหม่ เช่น:

```yaml
version: 0.1.0+3
```

`0.1.0` คือชื่อเวอร์ชัน (Android `versionName`) และ `3` หลัง `+` คือเลข build
(Android `versionCode`) สคริปต์ไม่เพิ่มเลขให้อัตโนมัติ เมื่อส่ง release ถัดไปให้เพิ่มเลข
หลัง `+` ในไฟล์ เช่น `0.1.0+4` แล้วรันคำสั่งเดิม

### Build และอัปโหลดด้วยคำสั่งเดียว

ติดตั้ง Firebase CLI และลงชื่อเข้าใช้บัญชีที่เข้าถึงโปรเจกต์ `burin-test` ก่อนใช้งานครั้งแรก:

```powershell
npm install -g firebase-tools
firebase login
```

สคริปต์ใช้บัญชี `burin@infsystemsgroup.com` เป็นค่าเริ่มต้นสำหรับ upload
สคริปต์จับคู่กับบัญชีที่ล็อกอินโดยไม่สนตัวพิมพ์เล็ก/ใหญ่ แล้วใช้ชื่อจริงที่ CLI บันทึกไว้
เช่น `Burin@infsystemsgroup.com` เพื่อป้องกัน `Account ... not found`
ตรวจบัญชีที่ล็อกอินใน CLI ด้วย `firebase login:list`
หากต้องเพิ่มบัญชี ให้รัน `firebase login:add` แล้วเลือก `burin@infsystemsgroup.com`
สามารถเลือกบัญชีประจำโปรเจกต์ด้วย `firebase login:use burin@infsystemsgroup.com`
หรือเปลี่ยนบัญชีที่สคริปต์ใช้ต่อคำสั่งผ่าน `-FirebaseAccount`:

```powershell
build-appdistribution -Upload -FirebaseAccount 'burin@infsystemsgroup.com' -ReleaseNotes 'Test build'
```

เมื่อใช้ `-Upload` สคริปต์จะตรวจสิทธิ์เข้าถึงโปรเจกต์ก่อนเริ่ม build
หากพบ `403 PERMISSION_DENIED` ให้ตรวจบัญชีที่ล็อกอินและสิทธิ์ในโปรเจกต์

จากนั้นรัน:

```powershell
.\scripts\build-appdistribution.ps1 -Upload -ReleaseNotes 'Fix notifications'
```

สคริปต์อ่าน Firebase App ID จาก `android/app/google-services.json` และตรวจว่าเป็น
โปรเจกต์ `burin-test` / package `com.example.flutter_application_1` ก่อน build
ถ้าไม่ระบุ `-Upload` จะสร้าง APK ไว้ในเครื่องเท่านั้น
ถ้าไม่ระบุผู้ทดสอบหรือกลุ่ม จะอัปโหลด release ไว้ใน Console เพื่อเลือกแจกภายหลัง

ส่งให้กลุ่มที่สร้างไว้ใน Firebase โดยใช้ **group alias** หรือระบุอีเมลผู้ทดสอบ:

```powershell
.\scripts\build-appdistribution.ps1 -Upload -Groups 'qa-team' -ReleaseNotes 'QA build'
.\scripts\build-appdistribution.ps1 -Upload -Testers 'tester@example.com' -ReleaseNotesFile .\release-notes.txt
```

`qa-team` และ `tester@example.com` เป็นตัวอย่าง ให้แทนด้วยกลุ่ม/ผู้ทดสอบจริง
ใช้ `-ReleaseNotes` หรือ `-ReleaseNotesFile` อย่างใดอย่างหนึ่ง โดย path ของไฟล์ notes
อ้างอิงจากโฟลเดอร์ที่เรียกคำสั่ง สคริปต์หยุดทันทีเมื่อ build หรือ upload ล้มเหลว

APK release นี้ยังเซ็นด้วย **debug key ตามการตั้งค่าเดิม** ใน `android/app/build.gradle.kts`
ซึ่ง Firebase App Distribution รองรับสำหรับทดสอบ ควรใช้ key เดิมกับทุก build เพื่อให้
อัปเดตทับแอปเดิมได้ หากเปลี่ยนเครื่องหรือเปลี่ยน signing key อาจต้องถอนแอปก่อนติดตั้งใหม่
สำหรับ Play Store ต้องตั้งค่า release signing key แยกต่างหาก

ตรวจสอบเมื่อ 18 พฤศจิกายน 2026: รันสคริปต์ build สำเร็จ ได้ release APK ขนาดประมาณ
45.4 MB, package `com.example.flutter_application_1`, version `0.1.0` (code `1`)
รองรับ `armeabi-v7a`, `arm64-v8a`, `x86_64` และผ่าน `apksigner verify` (v2)
ติดตั้ง Firebase CLI แล้ว; การอัปโหลดต้องใช้บัญชีที่มีสิทธิ์ในโปรเจกต์

ผลล่าสุด 18 พฤศจิกายน 2026: build APK `0.1.0` (code `2`) สำเร็จและผ่านการตรวจลายเซ็น
อัปโหลดผ่าน Firebase Console ด้วยบัญชี `burin@infsystemsgroup.com` สำเร็จแล้ว
หน้า Releases แสดง `0.1.0 (2)` พร้อมปุ่ม Download และ release notes `test`
ยังไม่ได้เพิ่มผู้ทดสอบหรือส่งคำเชิญ การล็อกอิน CLI แยกจากการล็อกอินในเบราว์เซอร์:
หากต้องการอัปโหลดครั้งถัดไปด้วยสคริปต์ ต้องเพิ่มบัญชีดังกล่าวผ่าน `firebase login:add` ก่อน

อ้างอิง: [Firebase: Distribute Android apps using the CLI](https://firebase.google.com/docs/app-distribution/android/distribute-cli)

## FCM เปิดหน้า test2 / test3 และบันทึกการกด (19 พฤศจิกายน 2026)

ส่ง payload ผ่าน API ส่ง FCM ของระบบ ตัวอย่าง:

```json
{
  "tokens": ["<FCM registration token จากมือถือ>"],
  "notification": {
    "title": "inf mobile test",
    "body": "hahaha"
  },
  "data": {
    "id": "notification-id-from-backend",
    "route": "/test2"
  }
}
```

| data.route | หน้าที่เปิด |
| --- | --- |
| `test2` หรือ `/test2` | test2 |
| `test3` หรือ `/test3` | test3 |
| ค่าว่างหรือค่าอื่น | หน้าข้อมูลแจ้งเตือน พร้อมแจ้งว่า route ไม่ตรง |

ทั้งสองหน้าแสดง title, body, ID, route และ JSON `data` ทั้งหมดจาก FCM รองรับ `data.id` และ `data.Id` โดยให้ `id` ที่ไม่ว่างมีลำดับก่อน ใช้ named routes ภายในแอปสำหรับ FCM; ไม่ได้เพิ่ม custom URL scheme หรือ Android App Links สำหรับลิงก์จากภายนอก

เมื่อกด system notification (foreground/local, background หรือ cold start) หรือกด **เปิดข้อความ** ในหน้าหลัก แอปจะเปิดหน้าปลายทางและส่ง:

```http
PATCH https://192.168.199.131:5000/api/noti/fcm/click
Accept: application/json
Content-Type: application/json

{"id":"notification-id-from-backend"}
```

- แค่รับข้อความยังไม่ส่ง click API; ปุ่มเปิด test2/test3 แบบไม่มีข้อความก็ไม่เรียก API
- เปลี่ยนหน้าโดยไม่รอ API และแสดงสถานะส่ง/สำเร็จ/ผิดพลาดบนหน้าปลายทาง
- ไม่มี ID: ยังอ่านข้อมูลได้ แต่ไม่ส่ง request ที่มี ID ว่าง
- callback ซ้ำของ message เดียวกันจะไม่เปิดหน้าและส่ง API ซ้ำในรอบการรันแอปเดียวกัน หากผู้ใช้กดเปิดข้อความเดิมในรายการอีกครั้ง จะส่ง API สำหรับการกดครั้งใหม่ (ยกเว้น request เดิมยังรอผลอยู่)
- HTTP 2xx ถือว่าสำเร็จ; HTTP error, เครือข่ายล้มเหลว หรือ timeout 10 วินาที แสดงข้อผิดพลาด และให้ผู้ใช้กดส่งสถานะอีกครั้ง ไม่มี automatic retry
- timeout ไม่ยืนยันว่า server ยังไม่ได้บันทึก; backend ควรรองรับการ PATCH ID เดิมซ้ำอย่างเหมาะสม
- รองรับ cold start โดยรอ Navigator พร้อมก่อนเปิดหน้า

ตรวจการเชื่อมต่อจริงด้วย HEAD โดยไม่ส่ง click: เครื่องพัฒนาปฏิเสธ HTTPS certificate ด้วย `SEC_E_UNTRUSTED_ROOT` จึงยังไม่ได้ยืนยัน PATCH กับ backend จริง ต้องใช้ HTTPS certificate ที่มือถือเชื่อถือและอยู่ในเครือข่ายที่เข้าถึง IP นี้ได้ ไม่มีการปิด certificate verification ในแอป

ถ้ามี URL HTTPS ที่ใช้ certificate ถูกต้อง สามารถกำหนดตอน build/run ได้:

```powershell
flutter run --dart-define=FCM_CLICK_URL=https://your-api.example.com/api/noti/fcm/click
```

ทดสอบ: ส่งข้อความไป test2/test3 แล้วกดตอนเปิดแอป, กด Home และตอนปิดแอป ตรวจข้อมูลหน้าปลายทางและสถานะ API ทดสอบอัตโนมัติด้วย `flutter test`: มี HTTP server ในเครื่องเพื่อตรวจ method/path/headers/body จริง, duplicate callback, HTTP 500, retry, timeout, ID หาย และ widget tests สำหรับ cold start/test3/back navigation การทดสอบเหล่านี้ไม่ได้ยืนยันการส่ง push บนมือถือจริงหรือผลบันทึกของ backend จริง

ผลตรวจสอบ 19 พฤศจิกายน 2026: `flutter analyze` ผ่านโดยไม่พบปัญหา, `flutter test` ผ่านทั้ง 7 กรณี และ `flutter build apk --debug` สำเร็จ (`build/app/outputs/flutter-apk/app-debug.apk`) ไม่ได้อัปโหลด App Distribution ในงานนี้

## หน้า page2 / page3 สำหรับทดสอบการคลิก FCM

เพิ่มหน้าแยก `lib/pages/page2.dart` และ `lib/pages/page3.dart` ลงทะเบียน route `/page2` และ `/page3` แล้ว รองรับ `data.route` ทั้ง `page2`, `/page2`, `page3`, `/page3` เมื่อกดแจ้งเตือนจะเปิดหน้าตาม route พร้อมข้อมูล FCM และเรียก click API ด้วย ID ตาม flow เดิม หน้าหลักมีปุ่มเปิด page2/page3 สำหรับดูหน้าได้ด้วย

ตัวอย่าง payload ที่ส่งจาก backend:

```json
{
  "tokens": ["<FCM token>"],
  "notification": {"title": "inf mobile test", "body": "hahaha"},
  "data": {"id": "notification-id", "route": "/page2"}
}
```

เปลี่ยน `route` เป็น `/page3` เพื่อทดสอบอีกหน้า ทั้งสองหน้าแสดง title, body, ID, route, JSON data และสถานะ click API

## เอกสารอ้างอิง

- [Firebase: Flutter FCM setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [Firebase: Receive messages](https://firebase.google.com/docs/cloud-messaging/flutter/receive)
- [Firebase: Android configuration](https://firebase.google.com/docs/android/setup)
