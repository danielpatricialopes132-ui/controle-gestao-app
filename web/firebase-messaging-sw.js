importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBh8Cf8UCo-CcXcEhDtjxEIwiBhjI8bx5E",
  authDomain: "controle-gestao-ea7ad.firebaseapp.com",
  projectId: "controle-gestao-ea7ad",
  storageBucket: "controle-gestao-ea7ad.firebasestorage.app",
  messagingSenderId: "487442618923",
  appId: "1:487442618923:web:5a4541ee0781d90274286e",
  measurementId: "G-NBJSLN5471"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
