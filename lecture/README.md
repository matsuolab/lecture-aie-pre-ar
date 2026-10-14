# مجلد للتمارين


## عرض توضيحي لـLinux
نهدف إلى الوصول إلى بنية الملفات والصلاحيات التالية.
تُعرض الصلاحيات بالصيغة الرمزية التي يُظهرها `ls -la` (مثل: `-rw-------`).

```بنية الملفات
lecture/                                        drwxr-xr-x
├── README.md                                   -rw-r--r--
├── docker-compose.yml                          -rw-r--r--
├── backend/                                     drwxr-xr-x
│   ├── Dockerfile                              -rw-r--r--
│   ├── main.py                                 -rw-r--r--
|   ├── .env                                    -rw-------  ← chmod 600 (للمالك فقط لأنه يحتوي على معلومات سرية)
|   ├── .env.example                            -rw-r--r--  ← قالب للمشاركة
│   ├── requirements.txt                        -rw-r--r--
└── frontend/                                    drwxr-xr-x
    ├── Dockerfile                              -rw-r--r--
    ├── index.html                              -rw-r--r--
    ├── package-lock.json                       -rw-r--r--
    ├── package.json                            -rw-r--r--
    ├── tsconfig.json                           -rw-r--r--
    ├── vite.config.ts                          -rw-r--r--
    └── src/                                     drwxr-xr-x
        ├── App.tsx                             -rw-r--r--
        └── main.tsx                            -rw-r--r--
```


## عرض توضيحي لـDocker
يمكنك تشغيل خادم التطوير باستخدام Docker compose.
```
cp backend/.env.example backend/.env && chmod 600 backend/.env   # في المرة الأولى فقط
docker compose up -d --build
```

### إذا ظهر الخطأ 504 عند الإرسال: «فشل الاتصال».
في Codespace، قد يسقط جدار الحماية القديم (iptables-legacy) الاتصالات بين الحاويات.
للسماح بالاتصال بين شبكات Compose (الأسماء التي تبدأ بـ`br-`)، نفّذ الأمر التالي مرة واحدة بعد بدء تشغيل Codespace.
```
sudo iptables-legacy -I FORWARD 1 -i br-+ -o br-+ -j ACCEPT
```
- يزول هذا الإعداد عند إعادة تشغيل Codespace (نفّذ الأمر مجددًا بعد إعادة التشغيل).
- للتراجع عن الإعداد: `sudo iptables-legacy -D FORWARD -i br-+ -o br-+ -j ACCEPT`

خادم التطوير متاح على العنوان التالي.
http://localhost:8080/