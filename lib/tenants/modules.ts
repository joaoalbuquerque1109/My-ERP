import type { TenantModule, TenantProfile } from "./types";

const MODULES: TenantModule[] = [
  { code: "core", label: "Núcleo", profile: "PRIVATE" },
  { code: "core", label: "Núcleo", profile: "PUBLIC" },
  { code: "billing", label: "Faturamento", profile: "PRIVATE" },
  { code: "accounts_receivable", label: "Contas a Receber", profile: "PRIVATE" },
  { code: "budgeting", label: "Orçamento", profile: "PUBLIC" },
  { code: "commitments", label: "Empenhos", profile: "PUBLIC" },
  { code: "hr", label: "Departamento Pessoal", profile: "PRIVATE" },
  { code: "hr", label: "Departamento Pessoal", profile: "PUBLIC" },
];

export function getVisibleModules(profile: TenantProfile): TenantModule[] {
  return MODULES.filter((module) => module.profile === profile);
}
