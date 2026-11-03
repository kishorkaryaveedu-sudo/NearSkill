/// App string constants for NearSkill
class AppStrings {
  AppStrings._();

  // App info
  static const String appName = 'NearSkill';
  static const String appTagline = 'Find skilled workers near you';

  // Auth strings
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String noAccount = "Don't have an account? ";
  static const String haveAccount = 'Already have an account? ';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';

  // Profile strings
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String displayName = 'Display Name';
  static const String phoneNumber = 'Phone Number';
  static const String bio = 'Bio';
  static const String skills = 'Skills';
  static const String hourlyRate = 'Hourly Rate';
  static const String becomeWorker = 'Become a Worker';
  static const String saveProfile = 'Save Profile';

  // Discovery strings
  static const String discover = 'Discover';
  static const String nearbyWorkers = 'Nearby Workers';
  static const String searchSkills = 'Search skills...';
  static const String noWorkersFound = 'No workers found nearby';
  static const String filterBySkill = 'Filter by skill';
  static const String distance = 'Distance';
  static const String perHour = '/hr';

  // Chat strings
  static const String messages = 'Messages';
  static const String typeMessage = 'Type a message...';
  static const String send = 'Send';
  static const String noMessages = 'No messages yet';
  static const String startConversation = 'Start a conversation';

  // Booking strings
  static const String bookings = 'Bookings';
  static const String bookNow = 'Book Now';
  static const String pending = 'Pending';
  static const String confirmed = 'Confirmed';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String noBookings = 'No bookings yet';

  // Common strings
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String done = 'Done';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String close = 'Close';
  static const String ok = 'OK';
  static const String yes = 'Yes';
  static const String no = 'No';

  // Error strings
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Please check your internet connection.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorWeakPassword =
      'Password must be at least 6 characters.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorEmptyField = 'This field cannot be empty.';
  static const String errorLocationPermission =
      'Location permission is required.';
  static const String errorLocationDisabled =
      'Please enable location services.';

  // Success strings
  static const String successProfileUpdated = 'Profile updated successfully!';
  static const String successBookingCreated = 'Booking created successfully!';
  static const String successMessageSent = 'Message sent!';
}
