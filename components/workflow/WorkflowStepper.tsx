type WorkflowStep = {
  id: string;
  label: string;
  status: "pending" | "active" | "complete";
};

type WorkflowStepperProps = {
  steps: WorkflowStep[];
};

export function WorkflowStepper({ steps }: WorkflowStepperProps) {
  return (
    <ol>
      {steps.map((step) => (
        <li key={step.id}>
          <strong>{step.label}</strong> — {step.status}
        </li>
      ))}
    </ol>
  );
}
