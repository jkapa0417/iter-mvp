// F0.4 — EXIF spike. Prove that lat/lng/taken_at can be pulled from real
// device photos. Uses photo_manager (NOT image_picker) because the Android
// system Photo Picker that image_picker invokes on API 33+ unconditionally
// redacts GPS metadata for privacy. photo_manager talks to MediaStore
// directly with ACCESS_MEDIA_LOCATION and returns the original bytes.

import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const ExifSpikeApp());
}

class ExifSpikeApp extends StatelessWidget {
  const ExifSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITER — F0.4 EXIF Spike',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExifSpikeScreen(),
    );
  }
}

class ExifSpikeScreen extends StatefulWidget {
  const ExifSpikeScreen({super.key});

  @override
  State<ExifSpikeScreen> createState() => _ExifSpikeScreenState();
}

class _ExifSpikeScreenState extends State<ExifSpikeScreen> {
  List<AssetEntity> _assets = [];
  ExifResult? _exif;
  String? _filePath;
  int? _fileBytes;
  String? _error;
  String? _status;
  bool _busy = false;

  Future<void> _loadAssets() async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Requesting permission…';
    });
    try {
      final perm = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: true,
          ),
        ),
      );
      if (!perm.isAuth) {
        setState(() {
          _error = 'Permission denied or limited: $perm';
          _busy = false;
        });
        return;
      }
      setState(() => _status = 'Loading recent photos…');
      // Default photo_manager order is ascending (oldest first). Force newest
      // first so the user lands on recent travel/camera shots, not 2018 stuff.
      final filterOption = FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      );
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: filterOption,
      );
      if (albums.isEmpty) {
        setState(() {
          _error = 'No photo albums found.';
          _busy = false;
        });
        return;
      }
      final assets = await albums.first.getAssetListPaged(page: 0, size: 500);
      setState(() {
        _assets = assets;
        _busy = false;
        _status =
            '${assets.length} photo(s) loaded. Scroll to find a GPS-tagged shot, then tap.';
      });
    } catch (e, st) {
      debugPrint('F0.4 _loadAssets error: $e\n$st');
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  Future<void> _onThumbTap(AssetEntity asset) async {
    await _parseAsset(asset);
    if (!mounted) return;
    if (_exif == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ExifSheet(
        exif: _exif!,
        filePath: _filePath,
        fileBytes: _fileBytes,
      ),
    );
  }

  Future<void> _parseAsset(AssetEntity asset) async {
    setState(() {
      _busy = true;
      _error = null;
      _exif = null;
      _status = 'Reading original bytes…';
    });
    try {
      final file = await asset.originFile;
      final bytes = await asset.originBytes;
      if (bytes == null) {
        setState(() {
          _error = 'originBytes returned null';
          _busy = false;
        });
        return;
      }
      final tags = await readExifFromBytes(bytes);
      final result = ExifResult.from(tags);

      // MediaStore-side coordinates (independent path; cross-check against EXIF).
      final latLng = await asset.latlngAsync();
      final mediaLat = latLng?.latitude;
      final mediaLng = latLng?.longitude;

      final rawLat =
          tags['GPS GPSLatitude']?.values.toList().toString() ?? '(no tag)';
      final rawLng =
          tags['GPS GPSLongitude']?.values.toList().toString() ?? '(no tag)';

      debugPrint('=== F0.4 EXIF SPIKE (photo_manager) ===');
      debugPrint('asset.id:        ${asset.id}');
      debugPrint('asset.title:     ${asset.title}');
      debugPrint('asset.mimeType:  ${asset.mimeType}');
      debugPrint('asset.size:      ${asset.width}x${asset.height}');
      debugPrint('origin file:     ${file?.path}');
      debugPrint('bytes:           ${bytes.length}');
      debugPrint('tag count:       ${tags.length}');
      debugPrint('raw GPS lat:     $rawLat');
      debugPrint('raw GPS lng:     $rawLng');
      debugPrint('EXIF lat:        ${result.lat}');
      debugPrint('EXIF lng:        ${result.lng}');
      debugPrint('MediaStore lat:  $mediaLat');
      debugPrint('MediaStore lng:  $mediaLng');
      debugPrint('taken_at:        ${result.takenAt}');
      debugPrint('createDateTime:  ${asset.createDateTime}');
      debugPrint('camera:          ${result.camera}');
      debugPrint('========================================');

      setState(() {
        _exif = result.copyWith(
          mediaLat: mediaLat,
          mediaLng: mediaLng,
          createDateTime: asset.createDateTime,
        );
        _filePath = file?.path;
        _fileBytes = bytes.length;
        _busy = false;
        _status = null;
      });
    } catch (e, st) {
      debugPrint('F0.4 _parseAsset error: $e\n$st');
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('F0.4 — EXIF spike (photo_manager)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _loadAssets,
              icon: const Icon(Icons.photo_library),
              label: Text(_busy ? 'Working…' : 'Load recent photos'),
            ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_status!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Error: $_error'),
                ),
              ),
            const SizedBox(height: 8),
            if (_assets.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: _assets.length,
                  itemBuilder: (context, i) {
                    final a = _assets[i];
                    return GestureDetector(
                      onTap: _busy ? null : () => _onThumbTap(a),
                      child: _Thumb(asset: a),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExifSheet extends StatelessWidget {
  const _ExifSheet({
    required this.exif,
    required this.filePath,
    required this.fileBytes,
  });
  final ExifResult exif;
  final String? filePath;
  final int? fileBytes;

  @override
  Widget build(BuildContext context) {
    final hasGps =
        exif.lat != null && !exif.lat!.startsWith('NaN');
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasGps
                    ? '✅ EXIF GPS extracted — feeds F2.5 directly.'
                    : '⚠️ No GPS — F2.4 manual picker would be needed.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              _row('File', filePath ?? ''),
              _row('Bytes', '${fileBytes ?? 0}'),
              const Divider(),
              _row('EXIF lat', exif.lat ?? '(missing)'),
              _row('EXIF lng', exif.lng ?? '(missing)'),
              _row('MediaStore lat',
                  exif.mediaLat?.toString() ?? '(missing)'),
              _row('MediaStore lng',
                  exif.mediaLng?.toString() ?? '(missing)'),
              _row('taken_at', exif.takenAt ?? '(missing)'),
              _row('createDateTime',
                  exif.createDateTime?.toString() ?? '(missing)'),
              _row('camera', exif.camera ?? '(missing)'),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.asset});
  final AssetEntity asset;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(160, 160)),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            width: 100,
            height: 100,
            color: Colors.black12,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snap.data == null) {
          return Container(
              width: 100, height: 100, color: Colors.black26);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            snap.data!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class ExifResult {
  ExifResult({
    this.lat,
    this.lng,
    this.takenAt,
    this.camera,
    this.mediaLat,
    this.mediaLng,
    this.createDateTime,
  });

  final String? lat;
  final String? lng;
  final String? takenAt;
  final String? camera;
  final double? mediaLat;
  final double? mediaLng;
  final DateTime? createDateTime;

  ExifResult copyWith({
    double? mediaLat,
    double? mediaLng,
    DateTime? createDateTime,
  }) =>
      ExifResult(
        lat: lat,
        lng: lng,
        takenAt: takenAt,
        camera: camera,
        mediaLat: mediaLat ?? this.mediaLat,
        mediaLng: mediaLng ?? this.mediaLng,
        createDateTime: createDateTime ?? this.createDateTime,
      );

  static ExifResult from(Map<String, IfdTag> tags) {
    return ExifResult(
      lat: _gps(tags, 'GPS GPSLatitude', 'GPS GPSLatitudeRef'),
      lng: _gps(tags, 'GPS GPSLongitude', 'GPS GPSLongitudeRef'),
      takenAt: tags['EXIF DateTimeOriginal']?.printable ??
          tags['Image DateTime']?.printable,
      camera: _camera(tags),
    );
  }

  static String? _camera(Map<String, IfdTag> tags) {
    final parts = [
      tags['Image Make']?.printable,
      tags['Image Model']?.printable,
    ].whereType<String>().toList();
    if (parts.isEmpty) return null;
    return parts.join(' ').trim();
  }

  static String? _gps(
      Map<String, IfdTag> tags, String coordKey, String refKey) {
    final coord = tags[coordKey];
    final ref = tags[refKey]?.printable;
    if (coord == null) return null;
    final values = coord.values.toList();
    if (values.length < 3) return null;
    double dec(int i) {
      final v = values[i];
      if (v is Ratio) {
        if (v.denominator == 0) return double.nan;
        return v.numerator / v.denominator;
      }
      return double.tryParse(v.toString()) ?? double.nan;
    }

    final degrees = dec(0) + dec(1) / 60 + dec(2) / 3600;
    if (degrees.isNaN) return 'NaN (zeroed by OS)';
    final signed = (ref == 'S' || ref == 'W') ? -degrees : degrees;
    return signed.toStringAsFixed(6);
  }
}
