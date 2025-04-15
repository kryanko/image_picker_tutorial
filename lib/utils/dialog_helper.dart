import 'package:flutter/material.dart';

Future<void> displayPickImageDialog({
  required BuildContext context,
  required bool isMulti,
  required TextEditingController maxWidthController,
  required TextEditingController maxHeightController,
  required TextEditingController qualitycontoller,
  required TextEditingController limitController,
  required void Function(
    double? maxWidth,
    double? maxHeight,
    int? quality,
    int? limit,
  )
  onPick,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Add optional parameters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: maxWidthController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter maxWidth if desired',
              ),
            ),
            TextField(
              controller: maxHeightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter maxHeight if desired',
              ),
            ),
            TextField(
              controller: qualitycontoller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter quality if desired',
              ),
            ),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter limit if desired',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('PICK'),
            onPressed: () {
              final double? width =
                  maxWidthController.text.isNotEmpty
                      ? double.tryParse(maxWidthController.text)
                      : null;
              final double? height =
                  maxHeightController.text.isNotEmpty
                      ? double.tryParse(maxHeightController.text)
                      : null;
              final int? quality =
                  qualitycontoller.text.isNotEmpty
                      ? int.tryParse(qualitycontoller.text)
                      : null;
              final int? limit =
                  limitController.text.isNotEmpty
                      ? int.tryParse(limitController.text)
                      : null;

              onPick(width, height, quality, limit);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
