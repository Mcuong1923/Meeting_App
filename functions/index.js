const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function này sẽ tự động được kích hoạt mỗi khi một người dùng mới
 * được tạo trong Firebase Authentication.
 *
 * Nhiệm vụ của nó là tạo một document tương ứng cho người dùng đó trong
 * collection 'users' trên Firestore.
 */
exports.createNewUserDocument = functions.auth.user().onCreate((user) => {
  // Lấy thông tin cần thiết từ user object
  const { uid, email, displayName, photoURL } = user;

  // Ghi log để debug (bạn có thể xem log này trong Google Cloud Console)
  console.log(`Tạo document cho người dùng mới: UID = ${uid}, Email = ${email}`);

  // Tạo một document mới trong collection 'users' với UID làm document ID
  return admin
    .firestore()
    .collection("users")
    .doc(uid)
    .set({
      email: email,
      displayName: displayName || "", // Dùng rỗng nếu displayName là null
      photoURL: photoURL || "", // Dùng rỗng nếu photoURL là null
      createdAt: admin.firestore.FieldValue.serverTimestamp(), // Thời gian tạo
      lastLoginAt: admin.firestore.FieldValue.serverTimestamp(), // Thời gian đăng nhập đầu tiên
      // Thêm các trường mặc định khác nếu cần
      // ví dụ: role: 'member',
    })
    .then(() => {
      console.log(`Đã tạo thành công document cho UID: ${uid}`);
      return null;
    })
    .catch((error) => {
      console.error(`Lỗi khi tạo document cho UID: ${uid}`, error);
      return null;
    });
}); 