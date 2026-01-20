type DataTableColumn<T> = {
  key: keyof T;
  label: string;
};

type DataTableProps<T extends Record<string, string | number>> = {
  columns: Array<DataTableColumn<T>>;
  rows: T[];
};

export function DataTable<T extends Record<string, string | number>>({
  columns,
  rows,
}: DataTableProps<T>) {
  return (
    <table style={{ width: "100%", borderCollapse: "collapse" }}>
      <thead>
        <tr>
          {columns.map((column) => (
            <th
              key={String(column.key)}
              style={{ textAlign: "left", padding: "8px" }}
            >
              {column.label}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((row, rowIndex) => (
          <tr key={rowIndex}>
            {columns.map((column) => (
              <td key={String(column.key)} style={{ padding: "8px" }}>
                {row[column.key]}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
