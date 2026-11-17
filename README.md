# Mastery App (Flutter)

Mastery E-Learning-এর Android ও iOS অ্যাপ। অ্যাপের ভেতরে https://mastery.com.bd/ ওয়েবসাইট WebView হিসেবে লোড হবে।

## Build
- Android: flutter build apk --release
- iOS: flutter build ios --release --no-codesign

GitHub Actions-এর Build Mastery App workflow Android APK ও unsigned iOS IPA আলাদা artifact হিসেবে তৈরি করে।

## Notes
- অ্যাপটি চালাতে ইন্টারনেট সংযোগ প্রয়োজন।
- Mastery-এর নিজস্ব পেজ এবং payment gateway অ্যাপের ভেতরে খোলে।
- Facebook, Instagram, YouTube, WhatsApp, Zoom ও Google Meet-এর মতো নির্দিষ্ট host বাইরে খোলে।
- iOS IPA-টি unsigned; বাস্তব iPhone-এ install করার আগে Apple Developer certificate ও provisioning profile দিয়ে sign করতে হবে।
