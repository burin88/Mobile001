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

## เอกสารอ้างอิง

- [Firebase: Flutter FCM setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [Firebase: Receive messages](https://firebase.google.com/docs/cloud-messaging/flutter/receive)
- [Firebase: Android configuration](https://firebase.google.com/docs/android/setup)
