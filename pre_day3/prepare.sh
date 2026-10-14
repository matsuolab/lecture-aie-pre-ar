#!/bin/sh

# هذا الملف برنامج إعداد لجلسة pre-Day3 (قسم التدريب على Docker).
# شغّله مرة واحدة قبل المحاضرة لتجنب الانتظار أثناءها.
# يُحفظ في pre_day3/prepare.sh داخل المستودع, ولتشغيله يكفي تنفيذ
#   chmod +x pre_day3/prepare.sh
#   ./pre_day3/prepare.sh
# هذين الأمرين فقط (وهما العمليتان اللتان تعلمتهما في pre-Day2).

# يتوقف فور حدوث خطأ أثناء التشغيل (-e).
# ويتوقف أيضًا عند محاولة استخدام قيمة لم تُعرّف (-u).
set -eu

# [1] نحدد إصداري صورة Docker ونموذج الذكاء الاصطناعي المطلوب تنزيلهما في متغيرات.
#     لا يُطلب من المتدربين تعديل هذا القسم.
IMAGE='ghcr.io/ggml-org/llama.cpp:server-v0.5.0'
MODEL_DIR='/workspaces/models'
MODEL_FILE='gemma-4-E2B-it-UD-Q4_K_XL.gguf'
MODEL_URL='https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/0314792d7f1f7e229411f620751375812bb9faf2/gemma-4-E2B-it-UD-Q4_K_XL.gguf'
MODEL_SHA256='b52f438017efaec5debf1c0d8be690571e212a07c312f1102bbce927258cfc32'
LLM_CHAT_DIR='/workspaces/llm-chat'
# المساحة الحرة المطلوبة: يبلغ حجم التنزيل نحو 3.5GB. نستخدم 4GB (4×1024×1024 KB) حدًا مرجعيًا لتوفير هامش إضافي.
REQUIRED_FREE_KB=4194304

# [2] يتحقق من إمكانية الاتصال بخادم Docker.
#     إذا تعذر الاتصال, يتوقف هنا ويوضح الخطوة التالية.
check_docker() {
  if ! docker version >/dev/null 2>&1; then
    printf '%s\n' 'خطأ: Docker غير متاح.' >&2
    printf '%s\n' 'إما أن تشغيل Docker في Codespace لم يكتمل بعد, أو أن البيئة لا تتيح استخدام Docker.' >&2
    printf '%s\n' 'انتظر بضع عشرات من الثواني, ثم نفّذ ./pre_day3/prepare.sh مجددًا.' >&2
    exit 1
  fi
}

# [3] يتحقق من المساحة الحرة في /workspaces.
#     إذا لم تكن كافية, يتوقف هنا ويوضح الخطوة التالية.
check_disk_space() {
  free_kb=$(df -Pk "$MODEL_DIR_PARENT" | awk 'NR==2 {print $4}')
  if [ "$free_kb" -lt "$REQUIRED_FREE_KB" ]; then
    printf '%s\n' 'خطأ: المساحة الحرة في /workspaces غير كافية.' >&2
    printf '%s\n' 'تحتاج إلى مساحة حرة تبلغ نحو 4GB أو أكثر (صورة Docker نحو 308MB, والنموذج نحو 3.2GB).' >&2
    printf '%s\n' 'احذف بيئة Codespace لا تستخدمها أو احذف الملفات غير الضرورية, ثم' >&2
    printf '%s\n' 'نفّذ ./pre_day3/prepare.sh مجددًا.' >&2
    exit 1
  fi
}

# [4] ينزّل صورة Docker الخاصة بـllama.cpp. إذا كانت منزّلة بالفعل, فلا يعيد تنزيلها.
pull_image() {
  if docker image inspect "$IMAGE" >/dev/null 2>&1; then
    printf '%s\n' "صورة Docker منزّلة بالفعل ($IMAGE). سيتم تخطي التنزيل."
    return 0
  fi
  printf '%s\n' "جارٍ تنزيل صورة Docker ($IMAGE). قد يستغرق ذلك عدة دقائق."
  if ! docker pull "$IMAGE"; then
    printf '%s\n' 'خطأ: تعذر تنزيل صورة Docker.' >&2
    printf '%s\n' 'تحقق من اتصال الشبكة, ثم نفّذ ./pre_day3/prepare.sh مجددًا.' >&2
    exit 1
  fi
}

# [5] يتحقق من تطابق SHA-256 للملف مع القيمة المتوقعة. يعيد 0 عند التطابق و1 عند عدم التطابق.
matches_sha256() {
  target_file="$1"
  [ -f "$target_file" ] || return 1
  actual=$(sha256sum "$target_file" | awk '{print $1}')
  [ "$actual" = "$MODEL_SHA256" ]
}

# [6] ينزّل ملف نموذج الذكاء الاصطناعي.
#     إذا كانت قيمة التحقق مطابقة, فلا يعيد التنزيل. ويحذف الملفات التي توقف تنزيلها قبل اكتماله ثم يعيد تنزيلها.
fetch_model() {
  mkdir -p "$MODEL_DIR"
  model_path="$MODEL_DIR/$MODEL_FILE"
  tmp_path="$model_path.download"

  if matches_sha256 "$model_path"; then
    printf '%s\n' "النموذج منزّل بالفعل ومحتواه مطابق ($model_path). سيتم تخطي التنزيل."
    return 0
  fi

  # يحذف أي ملف متبقٍ من تنزيل سابق لم يكتمل.
  rm -f "$tmp_path"

  printf '%s\n' 'جارٍ تنزيل النموذج. قد يستغرق ذلك نحو دقيقة.'
  if ! curl --fail --silent --show-error --location --output "$tmp_path" "$MODEL_URL"; then
    rm -f "$tmp_path"
    printf '%s\n' 'خطأ: تعذر تنزيل النموذج.' >&2
    printf '%s\n' 'تحقق من اتصال الشبكة, ثم نفّذ ./pre_day3/prepare.sh مجددًا.' >&2
    exit 1
  fi

  if ! matches_sha256 "$tmp_path"; then
    rm -f "$tmp_path"
    printf '%s\n' 'خطأ: محتوى النموذج المنزّل غير صحيح (قيمة SHA-256 غير مطابقة).' >&2
    printf '%s\n' 'ربما انقطع الاتصال أثناء التنزيل. نفّذ ./pre_day3/prepare.sh مجددًا.' >&2
    exit 1
  fi

  mv "$tmp_path" "$model_path"
  printf '%s\n' 'اكتمل تنزيل النموذج والتحقق من محتواه.'
}

# [7] يضع ملف Dockerfile الخاص بالذكاء الاصطناعي في /workspaces/llm-chat/Dockerfile.
#     محتواه مضمّن في هذا البرنامج (وهو مطابق لملف Dockerfile في صفحة المواد المتاحة).
place_llm_chat_dockerfile() {
  mkdir -p "$LLM_CHAT_DIR"
  cat > "$LLM_CHAT_DIR/Dockerfile" <<'DOCKERFILE'
# [1] الأساس (base image): صورة Docker تحتوي على خادم llama.cpp.
#     يُثبّت الإصدار (server-v0.5.0). قد يتغير المحتوى عند كل إعادة بناء إذا استُخدم latest.
FROM ghcr.io/ggml-org/llama.cpp:server-v0.5.0

# [2] الإعداد (environment variable): مسار النموذج المطلوب تحميله.
#     لا يُضمّن ملف النموذج في صورة Docker, بل يُتاح من خارجها في /models باستخدام -v (bind mount) مع docker run.
ENV LLAMA_ARG_MODEL=/models/gemma-4-E2B-it-UD-Q4_K_XL.gguf

# [3] الإعداد: منفذ استقبال الاتصالات (port). يستمع على 0.0.0.0 عند المنفذ 8080 لإتاحة الاتصال من خارج الحاوية.
ENV LLAMA_ARG_HOST=0.0.0.0
ENV LLAMA_ARG_PORT=8080

# [4] الإعداد: تعطيل الاستدلال (reasoning). طول المحادثة التي يمكن الاحتفاظ بها في الذاكرة (ctx-size).
#     الحد الأقصى لطول الإجابة الواحدة (n-predict).
ENV LLAMA_ARG_REASONING=off
ENV LLAMA_ARG_CTX_SIZE=4096
ENV LLAMA_ARG_N_PREDICT=256

# [5] الإعداد: التعليمة الأولى للذكاء الاصطناعي (system prompt). عند تعديلها وإعادة تنفيذ docker build,
#     تتغير طريقة إجابة الذكاء الاصطناعي. يكفي تعديل النص داخل "" في هذا السطر.
#     احرص على الحفاظ على تداخل علامات الاقتباس (الخارجية ' والداخلية ").
ENV LLAMA_ARG_UI_CONFIG='{"systemMessage":"أنت مساعد متعاون. أجب باختصار."}'
DOCKERFILE
  printf '%s\n' "تم وضع $LLM_CHAT_DIR/Dockerfile في موضعه."
}

# يبدأ هنا تسلسل التنفيذ (تُستدعى الدوال من [2] إلى [7] بهذا الترتيب).
MODEL_DIR_PARENT=$(dirname "$MODEL_DIR")
check_docker
check_disk_space
pull_image
fetch_model
place_llm_chat_dockerfile

printf '%s\n' 'اكتمل الإعداد'
