import './globals.css';

export const metadata = {
  title: 'Technical portfolio fixture',
  description: 'A fixed starter for the ReasonKit creative evaluation.'
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
