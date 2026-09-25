import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gov_app_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/network/providers.dart';

import '../../../../models/instrument_model.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../instruments/presentation/controllers/instruments_controller.dart';
import '../../../applications/presentation/controllers/applications_controller.dart';

import '../../../instruments/presentation/widgets/add_instrument_dialog.dart';
import '../../../instruments/presentation/widgets/apply_verification_dialog.dart';

import '../../../certificates/presentation/screens/certificate_view_screen.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState
    extends ConsumerState<OwnerDashboardScreen> {
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;

      ref
          .read(instrumentsControllerProvider.notifier)
          .loadInstruments(ownerId: user?.id);

      ref
          .read(applicationsControllerProvider.notifier)
          .loadApplications(ownerId: user?.id);
    });
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) >
            const Duration(seconds: 2)) {
      _lastBackPress = now;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );

      return false;
    }

    await SystemNavigator.pop();
    return true;
  }

  // ============================================================
  // ADD INSTRUMENT
  // ============================================================

  Future<void> _openAddInstrumentDialog() async {
    try {
      final created = await showDialog<InstrumentModel>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => const AddInstrumentDialog(),
      );

      if (created != null && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final user = ref.read(authControllerProvider).user;

        await ref
            .read(instrumentsControllerProvider.notifier)
            .loadInstruments(ownerId: user?.id);

        if (!mounted) return;

        setState(() {});

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Instrument Registered Successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${created.instrumentId} • ${created.type}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint(
        'Error opening AddInstrumentDialog: $e\n$st',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              'Could not open registration dialog: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // APPLY VERIFICATION
  // ============================================================

  void _openApplyVerificationDialog(
      InstrumentModel instrument) {
    showDialog(
      context: context,
      builder: (ctx) => ApplyVerificationDialog(
        instrument: instrument,
      ),
    );
  }

  // ============================================================
  // INSTRUMENT DETAILS DIALOG
  // ============================================================

  void _openInstrumentDetailsDialog(
      InstrumentModel instrument) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            10,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            12,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.precision_manufacturing,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Instrument Details',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer
                        .withValues(alpha: 0.45),
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INSTRUMENT ID',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instrument.instrumentId,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _detailRow(
                  'Instrument Type',
                  instrument.type,
                  Icons.category_outlined,
                ),

                _detailRow(
                  'Manufacturer',
                  instrument.manufacturer,
                  Icons.factory_outlined,
                ),

                _detailRow(
                  'Model',
                  instrument.model,
                  Icons.precision_manufacturing_outlined,
                ),

                _detailRow(
                  'Serial Number',
                  instrument.serialNumber,
                  Icons.tag,
                ),

                _detailRow(
                  'Capacity',
                  '${instrument.capacity} ${instrument.unit}',
                  Icons.scale_outlined,
                ),

                _detailRow(
                  'Manufacturing Year',
                  instrument.yearOfManufacture.toString(),
                  Icons.calendar_today_outlined,
                ),

                _detailRow(
                  'Business / Establishment',
                  instrument.locationName,
                  Icons.storefront_outlined,
                ),

                _detailRow(
                  'Installation Address',
                  instrument.address,
                  Icons.location_on_outlined,
                ),

                _detailRow(
                  'Coordinates',
                  '${instrument.latitude.toStringAsFixed(5)}°, '
                      '${instrument.longitude.toStringAsFixed(5)}°',
                  Icons.gps_fixed,
                ),

                _detailRow(
                  'Owner',
                  instrument.ownerName,
                  Icons.person_outline,
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    StatusBadge.fromStatus(
                      instrument.status.displayName,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (instrument.status ==
                    InstrumentStatus.registered ||
                instrument.status ==
                    InstrumentStatus.expired ||
                instrument.status ==
                    InstrumentStatus.reverificationDue)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openApplyVerificationDialog(
                    instrument,
                  );
                },
                icon: const Icon(
                  Icons.send,
                  size: 16,
                ),
                label: const Text(
                  'Apply Verification',
                ),
              ),

            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty
                      ? 'Not available'
                      : value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CERTIFICATE
  // ============================================================

  Future<void> _viewCertificate(
      InstrumentModel instrument) async {
    final certRepo =
        ref.read(certificateRepositoryProvider);

    final certs = await certRepo.getCertificates();

    final cert = certs.firstWhere(
      (c) =>
          c.instrumentId == instrument.id ||
          c.instrumentUniqueId ==
              instrument.instrumentId,
      orElse: () => certs.first,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CertificateViewScreen(
            certificate: cert,
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final authState =
        ref.watch(authControllerProvider);

    final instrumentsState =
        ref.watch(instrumentsControllerProvider);

    final applicationsState =
        ref.watch(applicationsControllerProvider);

    final instruments =
        instrumentsState.instruments;

    final applications =
        applicationsState.applications;

    final totalInstruments =
        instruments.length;

    final verifiedCount = instruments
        .where(
          (i) =>
              i.status ==
              InstrumentStatus.verified,
        )
        .length;

    final pendingApps = applications
        .where(
          (a) =>
              a.status.name !=
                  'certificateIssued' &&
              a.status.name != 'rejected' &&
              a.status.name != 'expired',
        )
        .length;

    final expiringSoon = instruments
        .where(
          (i) =>
              i.status ==
                  InstrumentStatus.reverificationDue ||
              i.status ==
                  InstrumentStatus.expired,
        )
        .length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (!didPop) {
          final canExit =
              await _onWillPop();

          if (canExit && mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: const GovAppHeader(
          title: 'E-MAAP • Owner Portal',
        ),

        body: Column(
          children: [
            OfflineBanner(
              isOffline:
                  authState.isOfflineSimulated,
              pendingSyncCount: 0,
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final user =
                      ref
                          .read(
                            authControllerProvider,
                          )
                          .user;

                  await ref
                      .read(
                        instrumentsControllerProvider
                            .notifier,
                      )
                      .loadInstruments(
                        ownerId: user?.id,
                      );
                },

                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // WELCOME BANNER
                      // ==================================================

                      AppCard(
                        backgroundColor:
                            AppColors.primary,
                        padding:
                            const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, '
                                    '${authState.user?.name ?? "Rahul Verma"} 👋',
                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w700,
                                      color:
                                          Colors.white,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    authState.user
                                            ?.department ??
                                        'Commercial Establishment',
                                    style:
                                        TextStyle(
                                      fontSize: 12,
                                      color: Colors
                                          .white
                                          .withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors.white
                                          .withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(4),
                                    ),
                                    child: Text(
                                      'Owner ID: '
                                      '${authState.user?.id ?? "usr-owner-01"}',
                                      style:
                                          const TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.white,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets.all(
                                      12),
                              decoration:
                                  BoxDecoration(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.15,
                                ),
                                shape:
                                    BoxShape.circle,
                              ),
                              child:
                                  const Icon(
                                Icons.storefront,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // STAT CARDS
                      // ==================================================

                      LayoutBuilder(
                        builder:
                            (context, constraints) {
                          final isWide =
                              constraints.maxWidth >=
                                  760;

                          return GridView.count(
                            crossAxisCount:
                                isWide ? 4 : 2,
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio:
                                isWide ? 2.0 : 1.6,
                            children: [
                              _StatCard(
                                title:
                                    'Total Instruments',
                                value:
                                    '$totalInstruments',
                                icon: Icons
                                    .precision_manufacturing,
                                color:
                                    AppColors.primary,
                              ),

                              _StatCard(
                                title:
                                    'Verified & Active',
                                value:
                                    '$verifiedCount',
                                icon:
                                    Icons.verified,
                                color:
                                    AppColors.success,
                              ),

                              _StatCard(
                                title:
                                    'Pending Applications',
                                value:
                                    '$pendingApps',
                                icon: Icons
                                    .pending_actions,
                                color:
                                    AppColors.warning,
                              ),

                              _StatCard(
                                title:
                                    'Expiring / Due Soon',
                                value:
                                    '$expiringSoon',
                                icon:
                                    Icons.alarm,
                                color:
                                    AppColors.error,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // QUICK ACTIONS
                      // ==================================================

                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              icon: Icons
                                  .add_circle_outline,
                              label:
                                  'Register Instrument',
                              onTap:
                                  _openAddInstrumentDialog,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: _ActionTile(
                              icon: Icons
                                  .assignment_turned_in_outlined,
                              label:
                                  'Apply Verification',
                              onTap: () {
                                if (instruments
                                    .isNotEmpty) {
                                  _openApplyVerificationDialog(
                                    instruments.first,
                                  );
                                } else {
                                  ScaffoldMessenger
                                      .of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please register an instrument first.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: _ActionTile(
                              icon: Icons
                                  .card_membership_outlined,
                              label:
                                  'View Certificates',
                              onTap: () {
                                final verified =
                                    instruments.where(
                                  (i) =>
                                      i.status ==
                                      InstrumentStatus
                                          .verified,
                                );

                                if (verified
                                    .isNotEmpty) {
                                  _viewCertificate(
                                    verified.first,
                                  );
                                } else {
                                  ScaffoldMessenger
                                      .of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No verified certificates issued yet.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // REGISTERED INSTRUMENTS
                      // ==================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          const Text(
                            'My Instruments',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                              color: AppColors
                                  .textPrimary,
                            ),
                          ),

                          TextButton.icon(
                            icon: const Icon(
                              Icons.add,
                              size: 16,
                            ),
                            label:
                                const Text(
                              'Add Equipment',
                            ),
                            onPressed:
                                _openAddInstrumentDialog,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ==================================================
                      // EMPTY STATE
                      // ==================================================

                      if (instruments.isEmpty)
                        AppCard(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 36,
                            horizontal: 20,
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets
                                        .all(16),
                                decoration:
                                    const BoxDecoration(
                                  color: AppColors
                                      .primaryContainer,
                                  shape:
                                      BoxShape.circle,
                                ),
                                child:
                                    const Icon(
                                  Icons.scale_outlined,
                                  size: 40,
                                  color: AppColors
                                      .primary,
                                ),
                              ),

                              const SizedBox(
                                  height: 14),

                              const Text(
                                'Your instrument portfolio is empty.',
                                style:
                                    TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: AppColors
                                      .textPrimary,
                                ),
                              ),

                              const SizedBox(
                                  height: 6),

                              const Text(
                                'No commercial weighing or measuring instruments registered yet under your business account.',
                                textAlign:
                                    TextAlign.center,
                                style:
                                    TextStyle(
                                  fontSize: 12,
                                  color: AppColors
                                      .textSecondary,
                                ),
                              ),

                              const SizedBox(
                                  height: 18),

                              ElevatedButton.icon(
                                icon:
                                    const Icon(
                                  Icons
                                      .add_circle,
                                  size: 18,
                                ),
                                label:
                                    const Text(
                                  '+ Add Your First Instrument',
                                ),
                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  minimumSize:
                                      const Size(
                                    240,
                                    44,
                                  ),
                                  backgroundColor:
                                      AppColors
                                          .primary,
                                ),
                                onPressed:
                                    _openAddInstrumentDialog,
                              ),
                            ],
                          ),
                        )

                      // ==================================================
                      // INSTRUMENT LIST
                      // ==================================================

                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              instruments.length,
                          separatorBuilder:
                              (context, index) =>
                                  const SizedBox(
                            height: 10,
                          ),

                          itemBuilder:
                              (context, index) {
                            final item =
                                instruments[index];

                            final isVerified =
                                item.status ==
                                    InstrumentStatus
                                        .verified;

                            final canApply =
                                item.status ==
                                        InstrumentStatus
                                            .registered ||
                                    item.status ==
                                        InstrumentStatus
                                            .expired ||
                                    item.status ==
                                        InstrumentStatus
                                            .reverificationDue;

                            // =================================================
                            // FIX:
                            // The complete instrument card is now clickable.
                            // =================================================

                            return InkWell(
                              onTap: () =>
                                  _openInstrumentDetailsDialog(
                                item,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),

                              child: AppCard(
                                padding:
                                    const EdgeInsets.all(
                                  14,
                                ),

                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets
                                                  .all(10),
                                          decoration:
                                              BoxDecoration(
                                            color: AppColors
                                                .primaryContainer,
                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              8,
                                            ),
                                          ),
                                          child:
                                              const Icon(
                                            Icons.scale,
                                            color: AppColors
                                                .primary,
                                            size: 24,
                                          ),
                                        ),

                                        const SizedBox(
                                            width: 12),

                                        Expanded(
                                          child:
                                              Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                item
                                                    .instrumentId,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .w800,
                                                  fontSize:
                                                      13,
                                                ),
                                                maxLines:
                                                    1,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                              ),

                                              Text(
                                                '${item.type} • ${item.capacity} ${item.unit}',
                                                style:
                                                    const TextStyle(
                                                  fontSize:
                                                      11,
                                                  color: AppColors
                                                      .textSecondary,
                                                ),
                                                maxLines:
                                                    2,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                              ),

                                              Text(
                                                'S/N: ${item.serialNumber}',
                                                style:
                                                    const TextStyle(
                                                  fontSize:
                                                      11,
                                                  color: AppColors
                                                      .textMuted,
                                                ),
                                                maxLines:
                                                    1,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                              ),

                                              if (item
                                                  .locationName
                                                  .isNotEmpty)
                                                Text(
                                                  '📍 ${item.locationName}',
                                                  style:
                                                      const TextStyle(
                                                    fontSize:
                                                        11,
                                                    color: AppColors
                                                        .textMuted,
                                                  ),
                                                  maxLines:
                                                      1,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),

                                        StatusBadge
                                            .fromStatus(
                                          item.status
                                              .displayName,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                        height: 10),

                                    const Divider(
                                      height: 1,
                                    ),

                                    const SizedBox(
                                        height: 8),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .end,
                                      children: [
                                        if (canApply)
                                          ElevatedButton
                                              .icon(
                                            style:
                                                ElevatedButton
                                                    .styleFrom(
                                              minimumSize:
                                                  const Size(
                                                150,
                                                34,
                                              ),
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal:
                                                    10,
                                              ),
                                            ),
                                            icon:
                                                const Icon(
                                              Icons.send,
                                              size: 14,
                                            ),
                                            label:
                                                const Text(
                                              'Apply Verification',
                                              style:
                                                  TextStyle(
                                                fontSize:
                                                    11,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _openApplyVerificationDialog(
                                              item,
                                            ),
                                          ),

                                        if (isVerified)
                                          ...[
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            OutlinedButton
                                                .icon(
                                              style:
                                                  OutlinedButton
                                                      .styleFrom(
                                                minimumSize:
                                                    const Size(
                                                  130,
                                                  34,
                                                ),
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal:
                                                      10,
                                                ),
                                              ),
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .qr_code,
                                                size: 14,
                                              ),
                                              label:
                                                  const Text(
                                                'View Certificate',
                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      11,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _viewCertificate(
                                                item,
                                              ),
                                            ),
                                          ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ================================================================
        // FLOATING ACTION BUTTON
        // ================================================================

        floatingActionButton:
            FloatingActionButton.extended(
          backgroundColor:
              AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Instrument',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed:
              _openAddInstrumentDialog,
        ),
      ),
    );
  }
}

// ==========================================================================
// STAT CARD
// ==========================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color:
                      AppColors.textSecondary,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: color,
              ),
            ],
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// ACTION TILE
// ==========================================================================

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),

            const SizedBox(height: 6),

            Text(
              label,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}