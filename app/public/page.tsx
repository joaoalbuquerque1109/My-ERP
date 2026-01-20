import { getVisibleModules } from "@/lib/tenants/modules";

export default function PublicHome() {
  const modules = getVisibleModules("PUBLIC");

  return (
    <>
      <h1>ERP Público</h1>
      <p>Ambiente configurado para órgãos públicos.</p>
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
