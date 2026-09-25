import 'package:flutter/material.dart';
import 'extrato_bancario_aba.dart';

class ExtratoBancarioScreen extends StatelessWidget {
  const ExtratoBancarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExtratoBancarioAba(showAppBar: true);
  }
}
