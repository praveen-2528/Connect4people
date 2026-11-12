import { User, CompanionProfile, Booking, Payment, sequelize } from '../models/index.js';

async function seedBookingsAndPayments() {
  console.log('Fetching users and companions to generate authentic bookings and payouts...');

  // Get users
  const companions = await User.findAll({
    where: { is_companion: true },
    include: [{ model: CompanionProfile, as: 'companion_profile' }],
    limit: 30
  });

  if (companions.length < 10) {
    console.error('Not enough companions to create bookings.');
    process.exit(1);
  }

  // Pick some companions to act as clients and others as companions
  const clients = companions.slice(0, 10);
  const activeComps = companions.slice(10, 30);

  const bookingBlueprints = [
    // Completed Bookings (Revenue generated!)
    {
      clientIdx: 0, compIdx: 0, bookingType: 'event', hours: 4, amount: 3500,
      status: 'completed', location: 'Taj Falaknuma Palace, Hyderabad',
      notes: 'Attended a cultural dinner & wedding reception. Excellent, polite companion.',
      paymentStatus: 'verified', upiRef: 'UPI/2026/89401827101/HDFC', method: 'UPI'
    },
    {
      clientIdx: 1, compIdx: 1, bookingType: 'hourly', hours: 3, amount: 2100,
      status: 'completed', location: 'Indiranagar 100ft Road, Bangalore',
      notes: 'Coffee & book discussion at café. Very engaging and knowledgeable.',
      paymentStatus: 'verified', upiRef: 'UPI/2026/77192830192/ICICI', method: 'GPay'
    },
    {
      clientIdx: 2, compIdx: 2, bookingType: 'event', hours: 5, amount: 4500,
      status: 'completed', location: 'The St. Regis, Lower Parel, Mumbai',
      notes: 'Formal gala dinner plus-one. Exceptionally well-mannered.',
      paymentStatus: 'verified', upiRef: 'UPI/2026/99281920381/SBI', method: 'PhonePe'
    },
    {
      clientIdx: 3, compIdx: 3, bookingType: 'hourly', hours: 2, amount: 1500,
      status: 'completed', location: 'Besant Nagar Beach & Café, Chennai',
      notes: 'Pleasant evening beach walk and filter coffee.',
      paymentStatus: 'verified', upiRef: 'UPI/2026/44910283910/Axis', method: 'UPI'
    },
    {
      clientIdx: 4, compIdx: 4, bookingType: 'event', hours: 6, amount: 5000,
      status: 'completed', location: 'Jubilee Hills International Centre, Hyderabad',
      notes: 'Family anniversary celebration. Gracious and respectful.',
      paymentStatus: 'verified', upiRef: 'UPI/2026/33910283912/HDFC', method: 'GPay'
    },
    {
      clientIdx: 5, compIdx: 5, bookingType: 'hourly', hours: 4, amount: 2800,
      status: 'completed', location: 'Cubbon Park & Lavelle Road, Bangalore',
      notes: 'Morning park walk and Italian bistro brunch.',
      paymentStatus: 'verified', upiRef: 'UPI/2026/11928301928/Paytm', method: 'UPI'
    },

    // Ongoing / Confirmed Bookings
    {
      clientIdx: 6, compIdx: 6, bookingType: 'event', hours: 4, amount: 3600,
      status: 'ongoing', location: 'Marine Drive & NCPA, Mumbai',
      notes: 'Live theatre show & dinner.',
      paymentStatus: 'verified', upiRef: 'UPI/2026/55910293819/ICICI', method: 'GPay'
    },
    {
      clientIdx: 7, compIdx: 7, bookingType: 'hourly', hours: 3, amount: 2250,
      status: 'accepted', location: 'Phoenix Marketcity, Chennai',
      notes: 'Weekend shopping & coffee.',
      paymentStatus: 'verified', upiRef: 'UPI/2026/66910293810/HDFC', method: 'UPI'
    },

    // PENDING BOOKINGS & PAYOUTS (Awaiting Admin Approval / Verification)
    {
      clientIdx: 8, compIdx: 8, bookingType: 'event', hours: 4, amount: 3200,
      status: 'pending', location: 'Novotel HICC, Hyderabad',
      notes: 'Corporate networking dinner. Pending payment confirmation.',
      paymentStatus: 'claimed', upiRef: 'UPI/2026/88491029381/SBI', method: 'GPay'
    },
    {
      clientIdx: 9, compIdx: 9, bookingType: 'hourly', hours: 3, amount: 2400,
      status: 'pending', location: 'UB City Rooftop, Bangalore',
      notes: 'Dinner reservation companion.',
      paymentStatus: 'claimed', upiRef: 'UPI/2026/99381920391/HDFC', method: 'PhonePe'
    },
    {
      clientIdx: 0, compIdx: 10, bookingType: 'event', hours: 5, amount: 4200,
      status: 'pending', location: 'Bandra Bandstand & Café, Mumbai',
      notes: 'Sunset walk & seaside dining.',
      paymentStatus: 'claimed', upiRef: 'UPI/2026/77381920311/ICICI', method: 'UPI'
    },
    {
      clientIdx: 1, compIdx: 11, bookingType: 'hourly', hours: 2, amount: 1600,
      status: 'pending', location: 'Mylapore Heritage Walk, Chennai',
      notes: 'Cultural temple walk & heritage tour.',
      paymentStatus: 'claimed', upiRef: 'UPI/2026/66381920399/Axis', method: 'Paytm'
    },

    // Cancelled / Declined Bookings
    {
      clientIdx: 2, compIdx: 12, bookingType: 'hourly', hours: 2, amount: 1400,
      status: 'cancelled', location: 'Inorbit Mall, Hyderabad',
      notes: 'Client cancelled due to travel schedule.',
      paymentStatus: 'rejected', upiRef: 'UPI/2026/CANCELLED/001', method: 'UPI'
    }
  ];

  let bookingsCreated = 0;
  let paymentsCreated = 0;

  for (const b of bookingBlueprints) {
    const client = clients[b.clientIdx];
    const comp = activeComps[b.compIdx];

    const platformFee = Math.round(b.amount * 0.20);
    const companionPayout = b.amount - platformFee;

    const startTime = new Date(Date.now() + 24 * 60 * 60 * 1000); // Tomorrow
    const endTime = new Date(startTime.getTime() + b.hours * 60 * 60 * 1000);

    const booking = await Booking.create({
      client_id: client.id,
      companion_id: comp.id,
      booking_type: b.bookingType,
      status: b.status,
      start_time: startTime,
      end_time: endTime,
      location: b.location,
      notes: b.notes,
      amount: b.amount,
      platform_fee: platformFee,
      companion_payout: companionPayout
    });
    bookingsCreated++;

    // Create payment linked to booking
    await Payment.create({
      user_id: client.id,
      booking_id: booking.id,
      payment_type: 'booking',
      amount: b.amount,
      status: b.paymentStatus,
      method: b.method,
      reference_note: b.upiRef,
      claimed_at: new Date(Date.now() - 2 * 60 * 60 * 1000),
      verified_at: b.paymentStatus === 'verified' ? new Date() : null
    });
    paymentsCreated++;
  }

  // Also seed some standalone Registration Fee payments (₹299)
  const regFeeUsers = companions.slice(15, 20);
  for (let i = 0; i < regFeeUsers.length; i++) {
    const u = regFeeUsers[i];
    const isPending = i < 3; // First 3 pending, rest verified
    await Payment.create({
      user_id: u.id,
      booking_id: null,
      payment_type: 'registration',
      amount: 299,
      status: isPending ? 'claimed' : 'verified',
      method: 'UPI',
      reference_note: `UPI/REG299/${u.phone?.replace(/[^0-9]/g, '').slice(-6) || '991823'}/PAY`,
      claimed_at: new Date(Date.now() - (i + 1) * 3600 * 1000),
      verified_at: isPending ? null : new Date()
    });
    paymentsCreated++;
  }

  console.log(`\n========================================`);
  console.log(`✅ Seeded ${bookingsCreated} real Bookings across Hyderabad, Bangalore, Mumbai, Chennai!`);
  console.log(`✅ Seeded ${paymentsCreated} Payments (Booking fees + ₹299 Registration fees)!`);
  console.log(`- 20% Platform Fee & 80% Companion Payout ledger populated.`);
  console.log(`- Pending payments ready for Admin 1-click Approval/Verification.`);
  console.log(`========================================\n`);

  process.exit(0);
}

seedBookingsAndPayments().catch(err => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
