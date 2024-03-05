export default function InfoLine(props: { title: string, children: React.ReactNode }) {
    return (
        <div style={{
            display: 'flex',
            flexFlow: 'wrap',
            justifyContent: 'space-between',
            alignItems: 'center',
            gap: '8px 12px',
        }}>
            <span>{props.title}</span>
            {props.children}
        </div>
    )
}