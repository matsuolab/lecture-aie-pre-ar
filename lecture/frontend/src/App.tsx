import { useState } from "react";

// لأن nginx يمرر /app/api إلى حاوية backend عبر وكيل عكسي,
// يكفي أن ترسل الواجهة الأمامية الطلب إلى مسار نسبي على الأصل الذي تُعرض منه
// (تثبيت localhost في الشيفرة يمنع وصول الطلب عند استخدام مضيف آخر مثل Codespace)
const API_URL = "/app/api";

export function App() {
  const [inputText, setInputText] = useState("");
  const [result, setResult] = useState("");

  const handleSend = async () => {
    if (!inputText) return;

    try {
      const response = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ input_text: inputText }),
      });

      if (!response.ok) {
        throw new Error("حدث خطأ في API");
      }

      const data = await response.json();
      setResult(`الرد: ${data.reply}`);
    } catch (error) {
      console.error(error);
      setResult("فشل الاتصال.");
    }
  };

  return (
    <>
      <h1>Docker Compose Demo</h1>
      <input
        type="text"
        placeholder="أدخل رسالة"
        value={inputText}
        onChange={(e) => setInputText(e.target.value)}
      />
      <button onClick={handleSend}>إرسال</button>
      <p>{result}</p>
    </>
  );
}
