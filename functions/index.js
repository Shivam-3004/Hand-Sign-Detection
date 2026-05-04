import emailjs from "emailjs-com";
import { db } from "./firebase"; // your firebase config
import { collection, addDoc } from "firebase/firestore";

const submitFeedback = async (formData) => {
  // Still save to Firestore if you want
  await addDoc(collection(db, "feedback"), formData);

  // Send email directly from frontend
  await emailjs.send(
    "service_qyrxwz9",    // from EmailJS dashboard
    "template_2ze0805",   // from EmailJS dashboard
    {
      name: formData.name,
      country: formData.country,
      occupation: formData.occupation,
      rating: formData.rating,
      feedback: formData.feedback,
    },
    "CH7VpL6RJY-KU9TXN"     // from EmailJS dashboard
  );
};