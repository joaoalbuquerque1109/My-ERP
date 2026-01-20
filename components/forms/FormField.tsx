type FormFieldProps = {
  label: string;
  name: string;
  type?: "text" | "number" | "date";
  required?: boolean;
};

export function FormField({
  label,
  name,
  type = "text",
  required = false,
}: FormFieldProps) {
  return (
    <label style={{ display: "grid", gap: "8px", marginBottom: "16px" }}>
      <span>
        {label} {required ? "*" : null}
      </span>
      <input name={name} type={type} required={required} />
    </label>
  );
}
