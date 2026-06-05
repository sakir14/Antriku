importScripts(
  'https://www.gstatic.com/firebasejs/12.13.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/12.13.0/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyD_SlV1LO-e4CEh8jTSyygz2ZEfPEfMN_I',
  appId: '1:791932772209:web:b785d112e8693ce3ca60d0',
  messagingSenderId: '791932772209',
  projectId: 'antriku-40d77',
  authDomain: 'antriku-40d77.firebaseapp.com',
  storageBucket: 'antriku-40d77.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};

  self.registration.showNotification(notification.title || 'AntriKu', {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  });
});
