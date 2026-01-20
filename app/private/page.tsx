import { getVisibleModules } from "@/lib/tenants/modules";

export default function PrivateHome() {
  const modules = getVisibleModules("PRIVATE");

  return (
    <>
      <h1>ERP Privado</h1>
      <p>Ambiente configurado para empresas privadas.</p>
      <section>
        <h2>Módulos habilitados</h2>
        <ul>
          {modules.map((module) => (
            <li key={module.code}>{module.label}</li>
          ))}
        </ul>
      </section>
    </>
  );
}
