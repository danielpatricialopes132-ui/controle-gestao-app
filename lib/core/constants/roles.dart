class AppRoles {
  // Acesso ilimitado a todas as empresas
  static const String master = 'MASTER';

  // Níveis de acesso por empresa (Tenant)
  static const String admin = 'ADMIN';           // Dono/Gestor da Empresa (Tudo liberado no tenant)
  static const String financeiro = 'FINANCEIRO'; // Acesso a fluxo de caixa, pagamentos, vales
  static const String engenharia = 'ENGENHARIA'; // Acesso apenas a controle de obras, medições
  static const String operacional = 'OPERACIONAL'; // Acesso básico (funcionário comum vendo seus vales/ponto)
}
