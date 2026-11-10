class MockData {
  static const String demoQrUrl =
      'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=upi%3A%2F%2Fpay%3Fpa%3Dconnect4people%40upi%26pn%3DConnect4People%26am%3D299';

  static Map<String, dynamic> get demoUser => {
        'id': 'u-rohit-001',
        'name': 'Rohit Malhotra',
        'email': 'demo@connect4people.com',
        'phone': '+91 9820012345',
        'role': 'user',
        'is_companion': false,
        'is_verified': true,
        'is_payment_verified': true,
        'is_active': true,
        'gender': 'Male',
        'city': 'Mumbai',
        'bio':
            'Tech entrepreneur and culture enthusiast. Looking for polite, well-mannered companions for social gatherings and dinners.',
        'avatar_url':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
        'companion_profile': {
          'id': 'cp-rohit-001',
          'user_id': 'u-rohit-001',
          'hourly_rate': 600,
          'event_rate': 3000,
          'tagline': 'Friendly dinner date & conversation companion',
          'avg_rating': 4.9,
          'total_bookings': 5,
          'languages': ['English', 'Hindi'],
          'interests': ['Dinner & Cafés', 'Movies & Theatre', 'Coffee & Conversations'],
          'available_days': ['Fri', 'Sat', 'Sun'],
          'is_listed': true,
        }
      };

  static List<Map<String, dynamic>> get companions => [
        {
          'id': 'cp-001',
          'user_id': 'u-ananya-001',
          'name': 'Ananya Sen',
          'avatar_url':
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80',
          'bio':
              'Fashion stylist and indie cinema lover. Polite, great listener, and excited about exploring modern cafés and live gigs.',
          'gender': 'Female',
          'city': 'Mumbai',
          'hourly_rate': 750,
          'event_rate': 3500,
          'tagline': 'Art lover, foodie & thoughtful companion for city events',
          'avg_rating': 4.9,
          'total_bookings': 18,
          'languages': ['English', 'Hindi', 'Bengali'],
          'interests': ['Dinner & Cafés', 'Movies & Theatre', 'Concerts & Festivals', 'Coffee & Conversations'],
          'available_days': ['Fri', 'Sat', 'Sun'],
          'photos': [
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80',
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=500&q=80',
          ]
        },
        {
          'id': 'cp-002',
          'user_id': 'u-kabir-002',
          'name': 'Kabir Mehta',
          'avatar_url':
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=500&q=80',
          'bio':
              'Fitness trainer and lively conversationalist. Great plus-one for family weddings, office galas, or weekend coffee.',
          'gender': 'Male',
          'city': 'Delhi NCR',
          'hourly_rate': 650,
          'event_rate': 3000,
          'tagline': 'Polite, well-mannered plus-one for weddings & parties',
          'avg_rating': 4.8,
          'total_bookings': 14,
          'languages': ['English', 'Hindi', 'Punjabi'],
          'interests': ['Weddings & Family Events', 'Dinner & Cafés', 'Sightseeing & City Tours'],
          'available_days': ['Mon', 'Wed', 'Fri', 'Sat', 'Sun'],
          'photos': [
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=500&q=80',
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=500&q=80',
          ]
        },
        {
          'id': 'cp-003',
          'user_id': 'u-rhea-003',
          'name': 'Rhea Deshmukh',
          'avatar_url':
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=500&q=80',
          'bio':
              'Architecture graduate who loves quiet café talks, heritage walks, and book reading sessions.',
          'gender': 'Female',
          'city': 'Pune',
          'hourly_rate': 500,
          'event_rate': 2400,
          'tagline': 'Calm and engaging conversationalist for coffee and art walks',
          'avg_rating': 4.95,
          'total_bookings': 22,
          'languages': ['English', 'Hindi', 'Marathi'],
          'interests': ['Coffee & Conversations', 'Casual Walks & Parks', 'Sightseeing & City Tours'],
          'available_days': ['Sat', 'Sun'],
          'photos': [
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=500&q=80',
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=500&q=80',
          ]
        },
        {
          'id': 'cp-004',
          'user_id': 'u-vikram-004',
          'name': 'Vikram Rao',
          'avatar_url':
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=500&q=80',
          'bio':
              'Product designer and film enthusiast. Always well-dressed, respectful, and punctual for corporate dinners and theatre.',
          'gender': 'Male',
          'city': 'Bengaluru',
          'hourly_rate': 800,
          'event_rate': 4000,
          'tagline': 'Tech-savvy, polite date for corporate dinners and theatre',
          'avg_rating': 4.85,
          'total_bookings': 12,
          'languages': ['English', 'Kannada', 'Hindi'],
          'interests': ['Dinner & Cafés', 'Movies & Theatre', 'Concerts & Festivals'],
          'available_days': ['Fri', 'Sat', 'Sun'],
          'photos': [
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=500&q=80',
          ]
        },
        {
          'id': 'cp-005',
          'user_id': 'u-pooja-005',
          'name': 'Pooja Hegde',
          'avatar_url':
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=500&q=80',
          'bio':
              'Literature graduate and travel enthusiast. Love deep conversations about books, philosophy, and local food.',
          'gender': 'Female',
          'city': 'Bengaluru',
          'hourly_rate': 900,
          'event_rate': 4500,
          'tagline': 'Warm personality, avid reader and wonderful companion',
          'avg_rating': 5.0,
          'total_bookings': 28,
          'languages': ['English', 'Hindi', 'Kannada'],
          'interests': ['Dinner & Cafés', 'Concerts & Festivals', 'Coffee & Conversations'],
          'available_days': ['Tue', 'Thu', 'Sat', 'Sun'],
          'photos': [
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=500&q=80',
          ]
        },
        {
          'id': 'cp-006',
          'user_id': 'u-arjun-006',
          'name': 'Arjun Verma',
          'avatar_url':
              'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=500&q=80',
          'bio':
              'Musician & brand marketer. Great sense of humor, easy-going, and loves music gigs and beach walks.',
          'gender': 'Male',
          'city': 'Mumbai',
          'hourly_rate': 600,
          'event_rate': 3200,
          'tagline': 'Casual dates, live gigs and memorable talks',
          'avg_rating': 4.75,
          'total_bookings': 9,
          'languages': ['English', 'Hindi'],
          'interests': ['Concerts & Festivals', 'Shopping & Malls', 'Casual Walks & Parks'],
          'available_days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          'photos': [
            'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=500&q=80',
          ]
        },
        {
          'id': 'cp-007',
          'user_id': 'u-sneha-007',
          'name': 'Sneha Kulkarni',
          'avatar_url':
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=500&q=80',
          'bio':
              'Software engineer by day, foodie by evening. Love discovering historical spots and cozy cafés in Hyderabad.',
          'gender': 'Female',
          'city': 'Hyderabad',
          'hourly_rate': 550,
          'event_rate': 2800,
          'tagline': 'Cheerful, cultured date for dinners & sightseeing',
          'avg_rating': 4.9,
          'total_bookings': 15,
          'languages': ['English', 'Hindi', 'Telugu'],
          'interests': ['Dinner & Cafés', 'Sightseeing & City Tours', 'Coffee & Conversations'],
          'available_days': ['Fri', 'Sat', 'Sun'],
          'photos': [
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=500&q=80',
          ]
        },
        {
          'id': 'cp-008',
          'user_id': 'u-aditya-008',
          'name': 'Aditya Nair',
          'avatar_url':
              'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=500&q=80',
          'bio':
              'Commercial photographer and coffee addict. Ready for cultural events, weddings, and weekend outings.',
          'gender': 'Male',
          'city': 'Chennai',
          'hourly_rate': 700,
          'event_rate': 3500,
          'tagline': 'Articulate photographer companion for events & outings',
          'avg_rating': 4.8,
          'total_bookings': 11,
          'languages': ['English', 'Tamil', 'Malayalam'],
          'interests': ['Weddings & Family Events', 'Sightseeing & City Tours', 'Coffee & Conversations'],
          'available_days': ['Sat', 'Sun'],
          'photos': [
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=500&q=80',
          ]
        },
      ];

  static List<Map<String, dynamic>> get clientBookings => [
        {
          'id': 'bk-001',
          'client_id': 'u-rohit-001',
          'companion_id': 'u-ananya-001',
          'status': 'accepted',
          'booking_type': 'hourly',
          'start_time': DateTime.now().add(const Duration(days: 1, hours: 2)).toIso8601String(),
          'end_time': DateTime.now().add(const Duration(days: 1, hours: 5)).toIso8601String(),
          'location': 'Café Coffee Day, Bandra Bandstand, Mumbai',
          'notes': 'Casual coffee conversation and promenade walk.',
          'amount': 2250.0,
          'platform_fee': 450.0,
          'companion_payout': 1800.0,
          'companion': {
            'id': 'u-ananya-001',
            'name': 'Ananya Sen',
            'avatar_url':
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80',
          }
        },
        {
          'id': 'bk-002',
          'client_id': 'u-rohit-001',
          'companion_id': 'u-kabir-002',
          'status': 'completed',
          'booking_type': 'event',
          'start_time': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
          'end_time': DateTime.now().subtract(const Duration(days: 4, hours: -5)).toIso8601String(),
          'location': 'Taj Palace Hotel, New Delhi',
          'notes': 'Friend wedding reception date.',
          'amount': 3000.0,
          'platform_fee': 600.0,
          'companion_payout': 2400.0,
          'companion': {
            'id': 'u-kabir-002',
            'name': 'Kabir Mehta',
            'avatar_url':
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=500&q=80',
          }
        },
      ];

  static List<Map<String, dynamic>> get companionBookings => [
        {
          'id': 'bk-req-001',
          'client_id': 'u-client-009',
          'companion_id': 'u-rohit-001',
          'status': 'pending',
          'booking_type': 'hourly',
          'start_time': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'end_time': DateTime.now().add(const Duration(days: 2, hours: 3)).toIso8601String(),
          'location': 'Starbucks, Lower Parel, Mumbai',
          'notes': 'Dinner meeting plus-one for business dinner.',
          'amount': 1800.0,
          'platform_fee': 360.0,
          'companion_payout': 1440.0,
          'client': {
            'id': 'u-client-009',
            'name': 'Meera Kapoor',
            'avatar_url':
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=500&q=80',
          }
        }
      ];

  static List<Map<String, dynamic>> get conversations => [
        {
          'id': 'conv-001',
          'other_user': {
            'id': 'u-ananya-001',
            'name': 'Ananya Sen',
            'avatar_url':
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80',
          },
          'last_message': {
            'id': 'msg-003',
            'conversation_id': 'conv-001',
            'sender_id': 'u-rohit-001',
            'content': 'Awesome! See you at 6 PM near the café entrance.',
            'message_type': 'text',
            'is_read': true,
            'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
          },
          'last_message_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
          'booking_id': 'bk-001',
        }
      ];

  static List<Map<String, dynamic>> get sampleMessages => [
        {
          'id': 'msg-001',
          'conversation_id': 'conv-001',
          'sender_id': 'u-rohit-001',
          'content': 'Hi Ananya! I submitted a booking request for tomorrow evening at Bandra.',
          'message_type': 'text',
          'is_read': true,
          'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
        {
          'id': 'msg-002',
          'conversation_id': 'conv-001',
          'sender_id': 'u-ananya-001',
          'content': 'Hello Rohit! Yes, I just accepted it. Looking forward to our coffee meetup!',
          'message_type': 'text',
          'is_read': true,
          'created_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        },
        {
          'id': 'msg-003',
          'conversation_id': 'conv-001',
          'sender_id': 'u-rohit-001',
          'content': 'Awesome! See you at 6 PM near the café entrance.',
          'message_type': 'text',
          'is_read': true,
          'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        },
      ];
}
