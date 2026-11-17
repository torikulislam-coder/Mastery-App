# Mastery App (Flutter)

Mastery E-Learning-এর Flutter অ্যাপ। একই কোড থেকে **Android APK** এবং **Web (ব্রাউজার লিংক)** দুটোই তৈরি হয়।

## APK পাওয়ার সহজ উপায় (GitHub Actions, কম্পিউটারে কিছু ইনস্টল লাগবে না)
1. GitHub-এ একটি নতুন repository খুলে এই ফোল্ডারের সব ফাইল আপলোড করুন (`.github` ফোল্ডারসহ)।
2. Repository-র **Actions** ট্যাবে **Build Mastery App** খুলে **Run workflow** চাপুন।
3. ৫–১০ মিনিট পর শেষ রানে **Artifacts**-এর নিচে `Mastery-APK` (Mastery.apk) ও `Mastery-Web` পাবেন।

## নিজের কম্পিউটারে (Linux/macOS/WSL, Flutter SDK ইনস্টল থাকলে)
```
bash build.sh
```
ফলাফল: `dist/Mastery.apk` এবং `dist/web/`

## ব্রাউজার লিংকে চালু করা
`dist/web/` ফোল্ডারের সব ফাইল একটি সাবডোমেইনে (যেমন app.mastery.com.bd, HTTPS সহ) আপলোড করুন। ফোনে খুলে "Add to Home Screen" দিলে Mastery লোগোসহ অ্যাপের মতো চলবে।

## ফোল্ডার
- `overlay/lib/main.dart`: অ্যাপের পুরো কোড
- `overlay/assets/`, `overlay/web/`, `overlay/android/`: Mastery লোগো ও আইকন
- `build.sh`: Flutter প্রজেক্ট তৈরি করে `overlay` বসায় এবং APK + Web বিল্ড করে

## জেনে রাখুন
- এই ভার্সনের কোর্স তালিকা mastery.com.bd থেকে নেওয়া স্থির ডেটা। Enroll, লগইন ও সাপোর্ট বাটন সরাসরি ওয়েবসাইট বা ফোন ডায়ালারে খোলে।
- লগইন, নিজের এনরোল করা কোর্স, ভিডিও প্লেয়ার ও নোটিফিকেশন পরের ধাপে যোগ হবে। এজন্য mastery.com.bd-এর API অ্যাক্সেস লাগবে।
- আপলোড করা লোগো ছোট (১৪৬×৬১) হওয়ায় আইকন একটু ঝাপসা। হাই-রেজোলিউশন PNG/SVG দিলে `overlay` ফোল্ডারের আইকনগুলো বদলে দেওয়া হবে।
- APK টি debug কী দিয়ে সাইন করা, সরাসরি ইনস্টল করা যাবে। Play Store-এ দিতে হলে নিজস্ব signing key লাগবে.
