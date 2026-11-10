import sequelize from '../config/database.js';
import UserModel from './User.js';
import CompanionProfileModel from './CompanionProfile.js';
import PhotoModel from './Photo.js';
import BookingModel from './Booking.js';
import ConversationModel from './Conversation.js';
import MessageModel from './Message.js';
import OtpCodeModel from './OtpCode.js';
import ReviewModel from './Review.js';
import ReportModel from './Report.js';
import PaymentModel from './Payment.js';
import AppConfigModel from './AppConfig.js';

// Initialize all models
const User = UserModel(sequelize);
const CompanionProfile = CompanionProfileModel(sequelize);
const Photo = PhotoModel(sequelize);
const Booking = BookingModel(sequelize);
const Conversation = ConversationModel(sequelize);
const Message = MessageModel(sequelize);
const OtpCode = OtpCodeModel(sequelize);
const Review = ReviewModel(sequelize);
const Report = ReportModel(sequelize);
const Payment = PaymentModel(sequelize);
const AppConfig = AppConfigModel(sequelize);

// ============================
// Associations
// ============================

// User <-> CompanionProfile (1:1)
User.hasOne(CompanionProfile, { foreignKey: 'user_id', as: 'companion_profile' });
CompanionProfile.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// User <-> Photos (1:N)
User.hasMany(Photo, { foreignKey: 'user_id', as: 'photos' });
Photo.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

// User <-> Bookings (as client)
User.hasMany(Booking, { foreignKey: 'client_id', as: 'client_bookings' });
Booking.belongsTo(User, { foreignKey: 'client_id', as: 'client' });

// User <-> Bookings (as companion)
User.hasMany(Booking, { foreignKey: 'companion_id', as: 'companion_bookings' });
Booking.belongsTo(User, { foreignKey: 'companion_id', as: 'companion' });

// Conversation <-> Users
Conversation.belongsTo(User, { foreignKey: 'user1_id', as: 'user1' });
Conversation.belongsTo(User, { foreignKey: 'user2_id', as: 'user2' });
User.hasMany(Conversation, { foreignKey: 'user1_id', as: 'conversations_as_user1' });
User.hasMany(Conversation, { foreignKey: 'user2_id', as: 'conversations_as_user2' });

// Conversation <-> Booking (optional)
Conversation.belongsTo(Booking, { foreignKey: 'booking_id', as: 'booking' });
Booking.hasOne(Conversation, { foreignKey: 'booking_id', as: 'conversation' });

// Conversation <-> Messages (1:N)
Conversation.hasMany(Message, { foreignKey: 'conversation_id', as: 'messages' });
Message.belongsTo(Conversation, { foreignKey: 'conversation_id', as: 'conversation' });

// Message <-> User (sender)
Message.belongsTo(User, { foreignKey: 'sender_id', as: 'sender' });
User.hasMany(Message, { foreignKey: 'sender_id', as: 'sent_messages' });

// Review <-> Booking
Review.belongsTo(Booking, { foreignKey: 'booking_id', as: 'booking' });
Booking.hasMany(Review, { foreignKey: 'booking_id', as: 'reviews' });

// Review <-> User (reviewer)
Review.belongsTo(User, { foreignKey: 'reviewer_id', as: 'reviewer' });
User.hasMany(Review, { foreignKey: 'reviewer_id', as: 'reviews_given' });

// Review <-> User (reviewee)
Review.belongsTo(User, { foreignKey: 'reviewee_id', as: 'reviewee' });
User.hasMany(Review, { foreignKey: 'reviewee_id', as: 'reviews_received' });

// Report <-> User (reporter)
Report.belongsTo(User, { foreignKey: 'reporter_id', as: 'reporter' });
User.hasMany(Report, { foreignKey: 'reporter_id', as: 'reports_filed' });

// Report <-> User (reported)
Report.belongsTo(User, { foreignKey: 'reported_user_id', as: 'reported_user' });
User.hasMany(Report, { foreignKey: 'reported_user_id', as: 'reports_against' });

// Report <-> Booking (optional)
Report.belongsTo(Booking, { foreignKey: 'booking_id', as: 'booking' });

// Payment <-> User
Payment.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
User.hasMany(Payment, { foreignKey: 'user_id', as: 'payments' });

// Payment <-> Booking (optional)
Payment.belongsTo(Booking, { foreignKey: 'booking_id', as: 'booking' });
Booking.hasMany(Payment, { foreignKey: 'booking_id', as: 'payments' });

export {
  sequelize,
  User,
  CompanionProfile,
  Photo,
  Booking,
  Conversation,
  Message,
  OtpCode,
  Review,
  Report,
  Payment,
  AppConfig
};

export default {
  sequelize,
  User,
  CompanionProfile,
  Photo,
  Booking,
  Conversation,
  Message,
  OtpCode,
  Review,
  Report,
  Payment,
  AppConfig
};
